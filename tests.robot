*** Settings ***
Library    RequestsLibrary
Library    Collections

Suite Setup       Create Api Session
Suite Teardown    Delete All Sessions
Test Teardown     Verify Clean State


*** Variables ***
${BASE_URL}       http://127.0.0.1:8000
${DEFAULT_UE_ID}    10


*** Keywords ***
Create Api Session
    Create Session    epc    ${BASE_URL}

Reset Simulator
    ${response}=    POST On Session    epc    /reset
    Should Be Equal As Integers    ${response.status_code}    200
    Should Be Equal    ${response.json()}[status]    reset

Get UE
    [Arguments]    ${ue_id}    ${expected_status}=200
    ${response}=    GET On Session    epc    /ues/${ue_id}    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    ${expected_status}
    RETURN    ${response}

Get UE List
    ${response}=    GET On Session    epc    /ues
    Should Be Equal As Integers    ${response.status_code}    200
    RETURN    ${response.json()}

Get UE Stats
    ${response}=    GET On Session    epc    /ues/stats
    Should Be Equal As Integers    ${response.status_code}    200
    RETURN    ${response.json()}

Attach UE
    [Arguments]    ${ue_id}
    ${body}=    Create Dictionary    ue_id=${ue_id}
    ${response}=    POST On Session    epc    /ues    json=${body}    expected_status=any
    RETURN    ${response}

Detach UE
    [Arguments]    ${ue_id}
    ${response}=    DELETE On Session    epc    /ues/${ue_id}    expected_status=any
    RETURN    ${response}

Verify UE Does Not Exist
    [Arguments]    ${ue_id}
    ${response}=    Get UE    ${ue_id}    400
    Should Be Equal    ${response.json()}[detail]    UE not found

Verify UE Exists
    [Arguments]    ${ue_id}
    ${response}=    Get UE    ${ue_id}    200
    Should Be Equal As Integers    ${response.json()}[ue_id]    ${ue_id}

Verify Stats Are Zero
    ${stats}=    Get UE Stats
    Should Be Equal As Integers    ${stats}[ue_count]         0
    Should Be Equal As Integers    ${stats}[bearer_count]     0
    Should Be Equal As Integers    ${stats}[total_tx_bps]     0
    Should Be Equal As Integers    ${stats}[total_rx_bps]     0

Verify Clean State
    Reset Simulator
    ${ues}=    Get UE List
    Length Should Be    ${ues}[ues]    0
    Verify Stats Are Zero


*** Test Cases ***
Detach_operation_on_disconnected_ue_error_scenario
    [Documentation]    Verify that detach operation is rejected for UE that is not connected to the network.
    [Tags]    negative    detach    ue

    ${ue_id}=    Set Variable    ${DEFAULT_UE_ID}

    Reset Simulator

    Log    Step 1: Verify UE is not attached to network
    Verify UE Does Not Exist    ${ue_id}

    Log    Step 2: Save initial system state
    ${stats_before}=    Get UE Stats

    Log    Step 3: Trigger detach operation for UE that is not connected
    ${detach_response}=    Detach UE    ${ue_id}

    Log    Step 4: Verify the system rejects the detach operation
    Should Be Equal As Integers    ${detach_response.status_code}    400

    Log    Step 5: Verify error message is returned
    Should Be Equal    ${detach_response.json()}[detail]    UE not found

    Log    Step 6: Verify UE state remains unchanged
    Verify UE Does Not Exist    ${ue_id}

    Log    Step 7: Verify no bearers are affected
    ${stats_after}=    Get UE Stats
    Should Be Equal As Integers    ${stats_after}[ue_count]         ${stats_before}[ue_count]
    Should Be Equal As Integers    ${stats_after}[bearer_count]     ${stats_before}[bearer_count]
    Should Be Equal As Integers    ${stats_after}[total_tx_bps]     ${stats_before}[total_tx_bps]
    Should Be Equal As Integers    ${stats_after}[total_rx_bps]     ${stats_before}[total_rx_bps]
