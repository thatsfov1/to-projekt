*** Settings ***
Resource    resources.robot

Suite Setup       Create Api Session
Suite Teardown    Delete All Sessions
Test Teardown     Verify Clean State


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