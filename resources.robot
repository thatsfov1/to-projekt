*** Settings ***
Library    RequestsLibrary
Library    Collections

*** Variables ***
${BASE_URL}       http://127.0.0.1:8000
${SESSION}        epc
${DEFAULT_UE_ID}    10
${DEFAULT_BEARER_ID}    9
${TEST_BEARER_ID}    1
${TRANSFER_SPEED_ABOVE_LIMIT_MBPS}    101


*** Keywords ***
Create Api Session
    Create Session    ${SESSION}    ${BASE_URL}

# RESET

Reset Simulator
    ${response}=    POST On Session    ${SESSION}    /reset
    Should Be Equal As Integers    ${response.status_code}    200
    Should Be Equal    ${response.json()}[status]    reset

Verify Clean State
    Reset Simulator
    ${ues}=    Get UE List
    Length Should Be    ${ues}[ues]    0
    Verify Stats Are Zero

# ==========================

# STATS

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

Verify Stats Are Zero
    ${stats}=    Get UE Stats
    Should Be Equal As Integers    ${stats}[ue_count]         0
    Should Be Equal As Integers    ${stats}[bearer_count]     0
    Should Be Equal As Integers    ${stats}[total_tx_bps]     0
    Should Be Equal As Integers    ${stats}[total_rx_bps]     0

# ==========================

# ATTACH/DETACH

Attach UE
    [Arguments]    ${ue_id}
    ${body}=    Create Dictionary    ue_id=${ue_id}
    ${response}=    POST On Session    ${SESSION}    /ues    json=${body}    expected_status=any
    RETURN    ${response}

Detach UE
    [Arguments]    ${ue_id}
    ${response}=    DELETE On Session    ${SESSION}    /ues/${ue_id}    expected_status=any
    RETURN    ${response}

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

# ==========================

# BEARER

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
    RETURN    ${response}

Remove Bearer
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=    DELETE On Session    ${SESSION}    /ues/${ue_id}/bearers/${bearer_id}    expected_status=any
    RETURN    ${response}

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


# ==========================

# UE

Verify UE Does Not Exist
    [Arguments]    ${ue_id}
    ${response}=    Get UE    ${ue_id}    400
    Should Be Equal    ${response.json()}[detail]    UE not found


Verify UE Exists
    [Arguments]    ${ue_id}
    ${response}=    Get UE    ${ue_id}    200
    Should Be Equal As Integers    ${response.json()}[ue_id]    ${ue_id}

# ==========================

# TRAFFIC 

Start Traffic
    [Arguments]    ${ue_id}    ${bearer_id}    ${mbps}    ${protocol}=tcp
    ${body}=    Create Dictionary    protocol=${protocol}    Mbps=${mbps}
    ${response}=    POST On Session    ${SESSION}    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=any
    RETURN    ${response}

Start Traffic And Verify
    [Arguments]    ${ue_id}    ${bearer_id}    ${mbps}    ${protocol}=tcp
    ${response}=    Start Traffic    ${ue_id}    ${bearer_id}    ${mbps}    ${protocol}
    Should Be Equal As Integers    ${response.status_code}    200
    
Stop Traffic
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=    DELETE On Session    ${SESSION}    /ues/${ue_id}/bearers/${bearer_id}/traffic    expected_status=any
    RETURN    ${response}

# ==========================

# DOMAIN LEVEL LANGUAGE KEYWORDS 

Start traffic is requested for UE ${ue_id} on bearer ${bearer_id} with ${mbps} transfer speed
    ${response}=    Start traffic    ${ue_id}    ${bearer_id}    ${mbps}
    Set Test Variable    ${START_TRAFFIC_RESPONSE}    ${response}

Traffic should not be active for UE ${ue_id} on bearer ${bearer_id}
    ${traffic}=    Get Traffic Stats    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${traffic.status_code}    200
    Should Be Equal As Integers    ${traffic.json()}[rx_bps]    0

Start traffic request should be rejected for UE ${ue_id} on bearer ${bearer_id}
    Should Be Equal As Integers    ${START_TRAFFIC_RESPONSE.status_code}    400

UE ${ue_id} is attached with default bearer
    Attach UE And Verify Default Bearer    ${ue_id}

Reattach UE ${ue_id} with default bearer
    ${response}=    Attach UE    ${ue_id}
    Verify UE Exists    ${ue_id}
    Verify Bearer Exists    ${ue_id}    ${DEFAULT_BEARER_ID}
    Set Test Variable    ${ATTACH_RESPONSE}    ${response}

UE ${ue_id} has dedicated bearer ${bearer_id}
    Add Bearer And Verify    ${ue_id}    ${bearer_id}

Dedicated bearer ${bearer_id} is removed from UE ${ue_id}
    ${response}=    Remove Bearer    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${response.status_code}    200

UE ${ue_id} should have bearer ${bearer_id}
    Verify Bearer Exists    ${ue_id}    ${bearer_id}

UE ${ue_id} should not have bearer ${bearer_id}
    Verify Bearer Does Not Exist    ${ue_id}    ${bearer_id}

UE ${ue_id} should still have default bearer
    Verify Bearer Exists    ${ue_id}    9

UE ${ue_id} is not connected to the network
    Verify UE Does Not Exist    ${ue_id}

Current system statistics are captured
    ${stats}=    Get UE Stats
    Set Test Variable    ${CAPTURED_STATS}    ${stats}

Detach is requested for UE ${ue_id}
    ${response}=    Detach UE    ${ue_id}
    Set Test Variable    ${DETACH_RESPONSE}    ${response}

Detach request for UE ${ue_id} should be rejected
    Should Be Equal As Integers    ${DETACH_RESPONSE.status_code}    400
    Should Be Equal    ${DETACH_RESPONSE.json()}[detail]    UE not found

Attach request for UE ${ue_id} should be rejected
    Should Be Equal As Integers    ${ATTACH_RESPONSE.status_code}    400

Attach request for UE ${ue_id} should be rejected with message ${error_message}
    Should Be Equal As Integers    ${ATTACH_RESPONSE.status_code}    400
    Should Be Equal    ${ATTACH_RESPONSE.json()}[detail]    ${error_message}

UE ${ue_id} should remain disconnected
    Verify UE Does Not Exist    ${ue_id}

System statistics should remain unchanged
    ${stats_after}=    Get UE Stats
    Should Be Equal As Integers    ${stats_after}[ue_count]         ${CAPTURED_STATS}[ue_count]
    Should Be Equal As Integers    ${stats_after}[bearer_count]     ${CAPTURED_STATS}[bearer_count]
    Should Be Equal As Integers    ${stats_after}[total_tx_bps]     ${CAPTURED_STATS}[total_tx_bps]
    Should Be Equal As Integers    ${stats_after}[total_rx_bps]     ${CAPTURED_STATS}[total_rx_bps]

Non-existing bearer ${bearer_id} is removed from UE ${ue_id}
    ${response}=    Remove Bearer    ${ue_id}    ${bearer_id}
    Set Test Variable    ${REMOVE_BEARER_RESPONSE}    ${response}

Remove request for bearer ${bearer_id} from UE ${ue_id} should be rejected
    Should Be Equal As Integers    ${REMOVE_BEARER_RESPONSE.status_code}    400
    Should Contain    ${REMOVE_BEARER_RESPONSE.json()}[detail]    Bearer

Attach duplicated bearer ${bearer_id} to UE ${ue_id}
    ${response}=    Add Bearer    ${ue_id}    ${bearer_id}
    Set Test Variable    ${ATTACH_RESPONSE}    ${response}

UE ${ue_id} is attached with active traffic on a dedicated bearer
    Attach UE And Verify Default Bearer    ${ue_id}
    Add Bearer And Verify    ${ue_id}    3
    Start Traffic And Verify    ${ue_id}    3    10
    Sleep    1s
    ${stats_active}=    Get UE Stats For UE    ${ue_id}
    Should Be True    ${stats_active}[total_rx_bps] > 0

UE ${ue_id} detaches and then reattaches
    Detach UE And Verify Gone    ${ue_id}
    Verify Stats Are Zero
    Attach UE And Verify Default Bearer    ${ue_id}

UE ${ue_id} should have no leftover traffic after reattach
    ${traffic_response}=    Get Traffic Stats    ${ue_id}    9
    Should Be Equal As Integers    ${traffic_response.status_code}    200
    Should Be Equal As Integers    ${traffic_response.json()}[rx_bps]    0
    ${stats_after_reattach}=    Get UE Stats For UE    ${ue_id}
    Should Be Equal As Integers    ${stats_after_reattach}[total_rx_bps]    0

Dedicated bearer used before detach should be removed for UE ${ue_id}
    Verify Bearer Does Not Exist    ${ue_id}    3

UE ${ue_id} is attached with default and three dedicated bearers
    Attach UE And Verify Default Bearer    ${ue_id}
    Add Bearer And Verify    ${ue_id}    1
    Add Bearer And Verify    ${ue_id}    2
    Add Bearer And Verify    ${ue_id}    3

UE ${ue_id} has traffic running on selected bearers
    Start Traffic And Verify    ${ue_id}    9    20
    Start Traffic And Verify    ${ue_id}    1    30
    Start Traffic And Verify    ${ue_id}    2    50
    Sleep    1s

Detailed traffic statistics are requested for UE ${ue_id}
    ${ue_stats}=        Get UE Stats For UE Details    ${ue_id}
    ${details}=         Set Variable    ${ue_stats}[details]
    ${ue_key}=          Convert To String    ${ue_id}
    ${ue_details}=      Set Variable    ${details}[${ue_key}]
    ${stats_3}=         Get Traffic Stats    ${ue_id}    3
    Set Test Variable    ${UE_STATS_WITH_DETAILS}    ${ue_stats}
    Set Test Variable    ${UE_DETAILS_FOR_TEST}      ${ue_details}
    Set Test Variable    ${TRAFFIC_STATS_BEARER_3}   ${stats_3}

Dedicated bearer without started traffic should report zero rate for UE ${ue_id}
    Should Be Equal As Integers    ${TRAFFIC_STATS_BEARER_3.status_code}    200
    Should Be Equal As Integers    ${TRAFFIC_STATS_BEARER_3.json()}[rx_bps]    0

Total UE traffic should equal the sum of per-bearer traffic for UE ${ue_id}
    ${rx_9}=            Set Variable    ${UE_DETAILS_FOR_TEST}[9]
    ${rx_1}=            Set Variable    ${UE_DETAILS_FOR_TEST}[1]
    ${rx_2}=            Set Variable    ${UE_DETAILS_FOR_TEST}[2]
    ${rx_3}=            Set Variable    ${TRAFFIC_STATS_BEARER_3.json()}[rx_bps]
    ${expected_total}=  Evaluate    ${rx_9} + ${rx_1} + ${rx_2} + ${rx_3}
    Should Be Equal As Integers    ${UE_STATS_WITH_DETAILS}[total_rx_bps]    ${expected_total}

UE ${ue_id} exists
    Verify UE Exists    ${ue_id}

Traffic is started for UE ${ue_id} on bearer ${bearer_id} with rate ${mbps}
    ${response}=    Start Traffic    ${ue_id}    ${bearer_id}    ${mbps}
    Should Be Equal As Integers    ${response.status_code}    200
    Sleep    1s

Traffic should be active for UE ${ue_id} on bearer ${bearer_id}
    ${traffic}=    Get Traffic Stats    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${traffic.status_code}    200
    Should Be True    ${traffic.json()}[rx_bps] > 0

    ${ue_stats}=    Get UE Stats For UE    ${ue_id}
    Should Be True    ${ue_stats}[total_rx_bps] > 0

Traffic is stopped for UE ${ue_id} on bearer ${bearer_id}
    ${response}=    Stop Traffic    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${response.status_code}    200

Traffic should be cleared for UE ${ue_id} on bearer ${bearer_id}
    ${traffic}=    Get Traffic Stats    ${ue_id}    ${bearer_id}
    Log    Bearer traffic after stop: ${traffic.json()}
    Should Be Equal As Integers    ${traffic.status_code}    200
    Should Be Equal As Integers    ${traffic.json()}[rx_bps]    0

UE ${ue_id} should have zero aggregated traffic statistics
    ${ue_stats}=    Get UE Stats For UE    ${ue_id}
    Log    UE stats after stop: ${ue_stats}
    Should Be Equal As Integers    ${ue_stats}[total_rx_bps]    0
    Should Be Equal As Integers    ${ue_stats}[total_tx_bps]    0

Verify zero aggregated traffic statistics for UE ${ue_id}
    ${ue_stats}=    Get UE Stats For UE    ${ue_id}
    Should Be Equal As Integers    ${ue_stats}[total_rx_bps]    0
    Should Be Equal As Integers    ${ue_stats}[total_tx_bps]    0

Dedicated bearer ${bearer_id} is added to UE ${ue_id}
    ${response}=    Add Bearer    ${ue_id}    ${bearer_id}
    Set Test Variable    ${ADD_BEARER_RESPONSE}    ${response}

Dedicated bearers ${bearer_id_one} and ${bearer_id_two} is added to UE ${ue_id}
    Add Bearer    ${ue_id}    ${bearer_id_one}
    Add Bearer    ${ue_id}    ${bearer_id_two}

Add bearer request for UE ${ue_id} should be rejected
    Should Be Equal As Integers    ${ADD_BEARER_RESPONSE.status_code}    400
    Should Be Equal    ${ADD_BEARER_RESPONSE.json()}[detail]    UE not found

UE ${ue_id_1} and UE ${ue_id_2} are attached and UE ${traffic_ue_id} has active traffic on bearer ${bearer_id}
    Attach UE And Verify Default Bearer    ${ue_id_1}
    Attach UE And Verify Default Bearer    ${ue_id_2}
    Add Bearer And Verify    ${traffic_ue_id}    ${bearer_id}
    Start Traffic And Verify    ${traffic_ue_id}    ${bearer_id}    35
    Sleep    1s

UE ${ue_id} should remain attached with active traffic on bearer ${bearer_id}
    Verify UE Exists    ${ue_id}
    Verify Bearer Exists    ${ue_id}    ${bearer_id}
    ${traffic}=    Get Traffic Stats    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${traffic.status_code}    200
    Should Be True    ${traffic.json()}[rx_bps] > 0

Total traffic for UE ${ue_id} should stay above zero
    ${ue_stats}=    Get UE Stats For UE    ${ue_id}
    Should Be True    ${ue_stats}[total_rx_bps] > 0

UE ${ue_id_1} and UE ${ue_id_2} are attached with default bearer
    Attach UE And Verify Default Bearer    ${ue_id_1}
    Attach UE And Verify Default Bearer    ${ue_id_2}

Attach is requested for out-of-range UE ${ue_id}
    ${response}=    Attach UE    ${ue_id}
    Set Test Variable    ${ATTACH_OUT_OF_RANGE_RESPONSE}    ${response}

Attach request for out-of-range UE ${ue_id} should be rejected
    Should Be Equal As Integers    ${ATTACH_OUT_OF_RANGE_RESPONSE.status_code}    400

Bearer list for UE ${ue_id} contains all of ${bearers} attached bearers
    ${response_list}=    Get UE    ${ue_id}
    ${count}=    Get Length    ${response_list.json()}[bearers]
    Should Be Equal As Integers    ${count}    3
    Dictionary Should Contain Key    ${response_list.json()}[bearers]    ${DEFAULT_BEARER_ID}

UE ${ue_id} has no bearer ${bearer_id}
    Verify Bearer Does Not Exist    ${ue_id}    ${bearer_id}

Default bearer is removed from UE ${ue_id}
    ${response}=    Remove Bearer    ${ue_id}    ${DEFAULT_BEARER_ID}
    Set Test Variable    ${REMOVE_DEFAULT_BEARER_RESPONSE}    ${response}

Remove default bearer request for UE ${ue_id} should be rejected
    Should Be Equal As Integers    ${REMOVE_DEFAULT_BEARER_RESPONSE.status_code}    400
    Should Be Equal    ${REMOVE_DEFAULT_BEARER_RESPONSE.json()}[detail]    Cannot remove default bearer

Remove bearer request for non-existing UE ${ue_id} should be rejected
    Should Be Equal As Integers    ${REMOVE_BEARER_RESPONSE.status_code}    400
    Should Be Equal    ${REMOVE_BEARER_RESPONSE.json()}[detail]    UE not found

Traffic request for non-existing UE ${ue_id} on bearer ${bearer_id} should be rejected
    ${traffic}=    Get Traffic Stats    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${traffic.status_code}    400
    Should Be Equal    ${traffic.json()}[detail]    UE not found