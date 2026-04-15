*** Settings ***
Library    RequestsLibrary
Library    Collections

*** Variables ***
${BASE_URL}       http://127.0.0.1:8000
${SESSION}        epc
${DEFAULT_UE_ID}    10


*** Keywords ***
Create Api Session
    Create Session    ${SESSION}    ${BASE_URL}


Reset Simulator
    ${response}=    POST On Session    ${SESSION}    /reset
    Should Be Equal As Integers    ${response.status_code}    200
    Should Be Equal    ${response.json()}[status]    reset


Get UE
    [Arguments]    ${ue_id}    ${expected_status}=200
    ${response}=    GET On Session    ${SESSION}    /ues/${ue_id}    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    ${expected_status}
    RETURN    ${response}


Get UE List
    ${response}=    GET On Session    ${SESSION}    /ues
    Should Be Equal As Integers    ${response.status_code}    200
    RETURN    ${response.json()}


Get UE Stats
    ${response}=    GET On Session    ${SESSION}    /ues/stats
    Should Be Equal As Integers    ${response.status_code}    200
    RETURN    ${response.json()}


Attach UE
    [Arguments]    ${ue_id}
    ${body}=    Create Dictionary    ue_id=${ue_id}
    ${response}=    POST On Session    ${SESSION}    /ues    json=${body}    expected_status=any
    RETURN    ${response}


Detach UE
    [Arguments]    ${ue_id}
    ${response}=    DELETE On Session    ${SESSION}    /ues/${ue_id}    expected_status=any
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


Attach UE And Verify Default Bearer
    [Arguments]    ${ue_id}
    ${response}=    Attach UE    ${ue_id}
    Should Be Equal As Integers    ${response.status_code}    200
    Verify UE Exists    ${ue_id}
    Verify Bearer Exists    ${ue_id}    9

Detach UE And Verify Gone
    [Arguments]    ${ue_id}
    ${response}=    Detach UE    ${ue_id}
    Should Be Equal As Integers    ${response.status_code}    200
    Verify UE Does Not Exist    ${ue_id}

Add Bearer
    [Arguments]    ${ue_id}    ${bearer_id}
    ${body}=    Create Dictionary    bearer_id=${bearer_id}
    ${response}=    POST On Session    ${SESSION}    /ues/${ue_id}/bearers    json=${body}    expected_status=any
    RETURN    ${response}

Add Bearer And Verify
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=    Add Bearer    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${response.status_code}    200
    Verify Bearer Exists    ${ue_id}    ${bearer_id}

Verify Bearer Exists
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=    GET On Session    ${SESSION}    /ues/${ue_id}    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    200
    Dictionary Should Contain Key    ${response.json()}[bearers]    ${bearer_id}

Verify Bearer Does Not Exist
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=    GET On Session    ${SESSION}    /ues/${ue_id}    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    200
    Dictionary Should Not Contain Key    ${response.json()}[bearers]    ${bearer_id}

Start Traffic
    [Arguments]    ${ue_id}    ${bearer_id}    ${mbps}    ${protocol}=tcp
    ${body}=    Create Dictionary    protocol=${protocol}    Mbps=${mbps}
    ${response}=    POST On Session    ${SESSION}    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=any
    RETURN    ${response}

Start Traffic And Verify
    [Arguments]    ${ue_id}    ${bearer_id}    ${mbps}    ${protocol}=tcp
    ${response}=    Start Traffic    ${ue_id}    ${bearer_id}    ${mbps}    ${protocol}
    Should Be Equal As Integers    ${response.status_code}    200

Get Traffic Stats
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=    GET On Session    ${SESSION}    /ues/${ue_id}/bearers/${bearer_id}/traffic    expected_status=any
    RETURN    ${response}

Get UE Stats For UE
    [Arguments]    ${ue_id}
    ${params}=      Create Dictionary    ue_id=${ue_id}
    ${response}=    GET On Session    ${SESSION}    /ues/stats    params=${params}    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    200
    RETURN    ${response.json()}


Get UE Stats For UE Details
    [Arguments]    ${ue_id}
    ${params}=      Create Dictionary    ue_id=${ue_id}    include_details=true
    ${response}=    GET On Session    ${SESSION}    /ues/stats    params=${params}    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    200
    RETURN    ${response.json()}

Remove Bearer
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=    DELETE On Session    ${SESSION}    /ues/${ue_id}/bearers/${bearer_id}    expected_status=any
    RETURN    ${response}

Given UE ${ue_id} is attached with default bearer
    Attach UE And Verify Default Bearer    ${ue_id}


UE ${ue_id} has dedicated bearer ${bearer_id}
    Add Bearer And Verify    ${ue_id}    ${bearer_id}


When dedicated bearer ${bearer_id} is removed from UE ${ue_id}
    ${response}=    Remove Bearer    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${response.status_code}    200


Then UE ${ue_id} should not have bearer ${bearer_id}
    Verify Bearer Does Not Exist    ${ue_id}    ${bearer_id}


UE ${ue_id} should still have default bearer
    Verify Bearer Exists    ${ue_id}    9

Given UE ${ue_id} is not connected to the network
    Verify UE Does Not Exist    ${ue_id}

Current system statistics are captured
    ${stats}=    Get UE Stats
    Set Test Variable    ${CAPTURED_STATS}    ${stats}

When detach is requested for UE ${ue_id}
    ${response}=    Detach UE    ${ue_id}
    Set Test Variable    ${DETACH_RESPONSE}    ${response}

Then detach request for UE ${ue_id} should be rejected
    Should Be Equal As Integers    ${DETACH_RESPONSE.status_code}    400
    Should Be Equal    ${DETACH_RESPONSE.json()}[detail]    UE not found

UE ${ue_id} should remain disconnected
    Verify UE Does Not Exist    ${ue_id}

System statistics should remain unchanged
    ${stats_after}=    Get UE Stats
    Should Be Equal As Integers    ${stats_after}[ue_count]         ${CAPTURED_STATS}[ue_count]
    Should Be Equal As Integers    ${stats_after}[bearer_count]     ${CAPTURED_STATS}[bearer_count]
    Should Be Equal As Integers    ${stats_after}[total_tx_bps]     ${CAPTURED_STATS}[total_tx_bps]
    Should Be Equal As Integers    ${stats_after}[total_rx_bps]     ${CAPTURED_STATS}[total_rx_bps]

When non-existing bearer ${bearer_id} is removed from UE ${ue_id}
    ${response}=    Remove Bearer    ${ue_id}    ${bearer_id}
    Set Test Variable    ${REMOVE_BEARER_RESPONSE}    ${response}

Then remove request for bearer ${bearer_id} from UE ${ue_id} should be rejected
    Should Be Equal As Integers    ${REMOVE_BEARER_RESPONSE.status_code}    400
    Should Contain    ${REMOVE_BEARER_RESPONSE.json()}[detail]    Bearer

UE ${ue_id} should not have bearer ${bearer_id}
    Verify Bearer Does Not Exist    ${ue_id}    ${bearer_id}