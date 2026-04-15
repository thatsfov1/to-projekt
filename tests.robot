*** Settings ***
Resource    resources.robot

Suite Setup       Create Api Session
Suite Teardown    Delete All Sessions
Test Setup        Reset Simulator
Test Teardown     Verify Clean State


*** Test Cases ***
Detach_operation_on_disconnected_ue_error_scenario
    [Documentation]    Verify that detach operation is rejected for UE that is not connected to the network.
    [Tags]    negative    detach    ue

    Given UE ${DEFAULT_UE_ID} is not connected to the network
    Current system statistics are captured
    When detach is requested for UE ${DEFAULT_UE_ID}
    Then detach request for UE ${DEFAULT_UE_ID} should be rejected
    UE ${DEFAULT_UE_ID} should remain disconnected
    System statistics should remain unchanged


Detach_clears_bearer_traffic_state_no_ghost_traffic_after_reattach
    [Documentation]    Verify that detach clears bearer traffic state and no ghost traffic appears after UE reattach.
    [Tags]    negative    attach    detach    bearer    traffic    state

    Attach UE And Verify Default Bearer    ${DEFAULT_UE_ID}
    Add Bearer And Verify    ${DEFAULT_UE_ID}    3
    Start Traffic And Verify    ${DEFAULT_UE_ID}    3    10
    Sleep    1s
    ${stats_active}=    Get UE Stats For UE    ${DEFAULT_UE_ID}
    Should Be True    ${stats_active}[total_rx_bps] > 0

    Detach UE And Verify Gone    ${DEFAULT_UE_ID}
    Verify Stats Are Zero

    Attach UE And Verify Default Bearer    ${DEFAULT_UE_ID}

    ${traffic_response}=    Get Traffic Stats    ${DEFAULT_UE_ID}    9
    Should Be Equal As Integers    ${traffic_response.status_code}    200
    Should Be Equal As Integers    ${traffic_response.json()}[rx_bps]    0

    ${stats_after_reattach}=    Get UE Stats For UE    ${DEFAULT_UE_ID}
    Should Be Equal As Integers    ${stats_after_reattach}[total_rx_bps]    0

    Verify Bearer Does Not Exist    ${DEFAULT_UE_ID}    3

Aggregated_traffic_stats_match_sum_of_per_bearer_rx_bps_and_default_bearer_add_rejected
    [Documentation]    Verify that aggregated UE traffic equals the sum of per-bearer RX rates.
    [Tags]    positive    negative    bearer    traffic    stats

    Attach UE And Verify Default Bearer    ${DEFAULT_UE_ID}
    Add Bearer And Verify    ${DEFAULT_UE_ID}    1
    Add Bearer And Verify    ${DEFAULT_UE_ID}    2
    Add Bearer And Verify    ${DEFAULT_UE_ID}    3
    Start Traffic And Verify    ${DEFAULT_UE_ID}    9    20
    Start Traffic And Verify    ${DEFAULT_UE_ID}    1    30
    Start Traffic And Verify    ${DEFAULT_UE_ID}    2    50
    Sleep    1s
    ${ue_stats}=        Get UE Stats For UE Details    ${DEFAULT_UE_ID}
    ${details}=         Set Variable    ${ue_stats}[details]
    Log    ${details}
    ${ue_key}=          Convert To String    ${DEFAULT_UE_ID}
    ${ue_details}=      Set Variable    ${details}[${ue_key}]
    ${stats_3}=         Get Traffic Stats    ${DEFAULT_UE_ID}    3
    ${rx_9}=            Set Variable    ${ue_details}[9]
    ${rx_1}=            Set Variable    ${ue_details}[1]
    ${rx_2}=            Set Variable    ${ue_details}[2]
    ${rx_3}=            Set Variable    ${stats_3.json()}[rx_bps]
    Should Be Equal As Integers    ${rx_3}    0
    ${expected_total}=  Evaluate    ${rx_9} + ${rx_1} + ${rx_2} + ${rx_3}
    Should Be Equal As Integers    ${ue_stats}[total_rx_bps]    ${expected_total}

Start_traffic_rejected_for_value_above_max_limit
    [Documentation]    Verify that traffic start is rejected when requested transfer exceeds maximum allowed limit (100 Mbps).
    [Tags]    negative    traffic    bearer    validation

    ${ue_id}=    Set Variable    ${DEFAULT_UE_ID}
    ${invalid_rate}=    Set Variable    101

    Log    Step 1: Attach UE and verify default bearer exists
    Attach UE And Verify Default Bearer    ${ue_id}

    Log    Step 2: Save initial stats
    ${stats_before}=    Get UE Stats For UE    ${ue_id}

    Log    Step 3: Attempt to start traffic above maximum limit
    ${response}=    Start Traffic    ${ue_id}    9    ${invalid_rate}

    Log    Step 4: Verify request is rejected
    Should Be Equal As Integers    ${response.status_code}    400

    Log    Step 5: Verify error message
    Should Be Equal    ${response.json()}[detail]    Invalid transfer rate

    Log    Step 6: Verify no traffic was started
    ${traffic}=    Get Traffic Stats    ${ue_id}    9
    Should Be Equal As Integers    ${traffic.json()}[rx_bps]    0

    Log    Step 7: Verify system stats remain unchanged
    ${stats_after}=    Get UE Stats For UE    ${ue_id}
    Should Be Equal As Integers    ${stats_after}[total_rx_bps]    ${stats_before}[total_rx_bps]
    Should Be Equal As Integers    ${stats_after}[total_tx_bps]    ${stats_before}[total_tx_bps]

Add_dedicated_bearer_success_scenario
    [Documentation]    Verify that a dedicated bearer can be added to an attached UE.
    [Tags]    positive    bearer    add

    ${ue_id}=        Set Variable    ${DEFAULT_UE_ID}
    ${bearer_id}=    Set Variable    1

    Log    Step 1: Attach UE and verify default bearer exists
    Attach UE And Verify Default Bearer    ${ue_id}

    Log    Step 2: Add dedicated bearer and verify it exists
    Add Bearer And Verify    ${ue_id}    ${bearer_id}

Add_bearer_rejected_for_duplicate_bearer_id
    [Documentation]    Verify that adding the same bearer twice is rejected.
    [Tags]    negative    bearer    add

    ${ue_id}=        Set Variable    ${DEFAULT_UE_ID}
    ${bearer_id}=    Set Variable    1

    Log    Step 1: Attach UE
    Attach UE And Verify Default Bearer    ${ue_id}

    Log    Step 2: Add bearer for the first time
    Add Bearer And Verify    ${ue_id}    ${bearer_id}

    Log    Step 3: Try to add the same bearer again
    ${response}=    Add Bearer    ${ue_id}    ${bearer_id}

    Log    Step 4: Verify request is rejected
    Should Be Equal As Integers    ${response.status_code}    400

    Log    Step 5: Verify error message
    Should Contain    ${response.json()}[detail]    Bearer

    Log    Step 6: Verify bearer still exists only once
    Verify Bearer Exists    ${ue_id}    ${bearer_id}

Remove_dedicated_bearer_success_scenario
    [Documentation]    Verify that a dedicated bearer can be removed successfully from an attached UE.
    [Tags]    positive    bearer    remove

    Given UE ${DEFAULT_UE_ID} is attached with default bearer
    UE ${DEFAULT_UE_ID} has dedicated bearer 1
    When dedicated bearer 1 is removed from UE ${DEFAULT_UE_ID}
    Then UE ${DEFAULT_UE_ID} should not have bearer 1
    UE ${DEFAULT_UE_ID} should still have default bearer

Remove_non_existing_bearer_rejected_scenario
    [Documentation]    Verify that removing a non-existing dedicated bearer is rejected.
    [Tags]    negative    bearer    remove

    Given UE ${DEFAULT_UE_ID} is attached with default bearer
    When non-existing bearer 3 is removed from UE ${DEFAULT_UE_ID}
    Then remove request for bearer 3 from UE ${DEFAULT_UE_ID} should be rejected
    UE ${DEFAULT_UE_ID} should still have default bearer
    UE ${DEFAULT_UE_ID} should not have bearer 3

Remove_default_bearer_rejected
    [Documentation]    Verify that removing default bearer (ID=9) is not allowed.
    [Tags]    negative    bearer    remove    validation

    ${ue_id}=    Set Variable    ${DEFAULT_UE_ID}

    Log    Step 1: Attach UE with default bearer
    Attach UE And Verify Default Bearer    ${ue_id}

    Log    Step 2: Attempt to remove default bearer
    ${response}=    Remove Bearer    ${ue_id}    9

    Log    Step 3: Verify request is rejected
    Should Be Equal As Integers    ${response.status_code}    400

    Log    Step 4: Verify error message
    Should Contain    ${response.json()}[detail]    default

    Log    Step 5: Verify default bearer still exists
    Verify Bearer Exists    ${ue_id}    9

Start_traffic_for_non_existing_bearer_rejected
    [Documentation]    Verify that starting traffic on non-existing bearer is rejected.
    [Tags]    negative    traffic    bearer    validation

    ${ue_id}=        Set Variable    ${DEFAULT_UE_ID}
    ${bearer_id}=    Set Variable    5

    Log    Step 1: Attach UE (only default bearer exists)
    Attach UE And Verify Default Bearer    ${ue_id}

    Log    Step 2: Attempt to start traffic on non-existing bearer
    ${response}=    Start Traffic    ${ue_id}    ${bearer_id}    10

    Log    Step 3: Verify request is rejected
    Should Be Equal As Integers    ${response.status_code}    400

    Log    Step 4: Verify error message
    Should Contain    ${response.json()}[detail]    Bearer

    Log    Step 5: Verify no traffic started on default bearer
    ${traffic}=    Get Traffic Stats    ${ue_id}    9
    Should Be Equal As Integers    ${traffic.json()}[rx_bps]    0