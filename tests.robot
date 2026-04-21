*** Settings ***
Resource    resources.robot

Suite Setup       Create Api Session
Suite Teardown    Delete All Sessions
Test Setup        Reset Simulator
Test Teardown     Verify Clean State

*** Test Cases ***

# Szymon

Remove_dedicated_bearer_success_scenario
    [Documentation]    Verify that a dedicated bearer can be removed successfully from an attached UE.
    [Tags]    positive    bearer    remove

    Given UE ${DEFAULT_UE_ID} is attached with default bearer
    And UE ${DEFAULT_UE_ID} has dedicated bearer 1
    When dedicated bearer 1 is removed from UE ${DEFAULT_UE_ID}
    Then UE ${DEFAULT_UE_ID} should not have bearer 1
    And UE ${DEFAULT_UE_ID} should still have default bearer

Detach_operation_on_disconnected_ue_error_scenario
    [Documentation]    Verify that detach operation is rejected for UE that is not connected to the network.
    [Tags]    negative    detach    ue

    Given UE ${DEFAULT_UE_ID} is not connected to the network
    And Current system statistics are captured
    When detach is requested for UE ${DEFAULT_UE_ID}
    Then detach request for UE ${DEFAULT_UE_ID} should be rejected
    And UE ${DEFAULT_UE_ID} should remain disconnected
    And System statistics should remain unchanged

Remove_non_existing_bearer_rejected_scenario
    [Documentation]    Verify that removing a non-existing dedicated bearer is rejected.
    [Tags]    negative    bearer    remove

    Given UE ${DEFAULT_UE_ID} is attached with default bearer
    When non-existing bearer 3 is removed from UE ${DEFAULT_UE_ID}
    Then remove request for bearer 3 from UE ${DEFAULT_UE_ID} should be rejected
    And UE ${DEFAULT_UE_ID} should still have default bearer
    And UE ${DEFAULT_UE_ID} should not have bearer 3

Stop_traffic_clears_bearer_and_ue_statistics_scenario
    [Documentation]    Verify that stopping traffic clears bearer traffic counters and aggregated UE statistics.
    [Tags]    positive    traffic    bearer    stop    stats

    Given UE ${DEFAULT_UE_ID} is attached with default bearer
    When traffic is started for UE ${DEFAULT_UE_ID} on bearer ${DEFAULT_BEARER_ID} with rate 25
    Then traffic should be active for UE ${DEFAULT_UE_ID} on bearer ${DEFAULT_BEARER_ID}
    When traffic is stopped for UE ${DEFAULT_UE_ID} on bearer ${DEFAULT_BEARER_ID}
    Then traffic should be cleared for UE ${DEFAULT_UE_ID} on bearer ${DEFAULT_BEARER_ID}
    UE ${DEFAULT_UE_ID} should have zero aggregated traffic statistics

Add_bearer_to_non_existing_ue_rejected_scenario
    [Documentation]    Verify that adding a dedicated bearer to a non-existing UE is rejected.
    [Tags]    negative    bearer    add    ue

    Given UE ${DEFAULT_UE_ID} is not connected to the network
    Current system statistics are captured
    When dedicated bearer ${TEST_BEARER_ID} is added to UE ${DEFAULT_UE_ID}
    Then add bearer request for UE ${DEFAULT_UE_ID} should be rejected
    UE ${DEFAULT_UE_ID} should remain disconnected
    System statistics should remain unchanged

# ==========================

# Yevhenii

Detach_clears_bearer_traffic_state_no_ghost_traffic_after_reattach
    [Documentation]    Verify that detach clears bearer traffic state and no ghost traffic appears after UE reattach.
    [Tags]    negative    attach    detach    bearer    traffic    state

    Given UE ${DEFAULT_UE_ID} is attached with active traffic on a dedicated bearer
    When UE ${DEFAULT_UE_ID} detaches and then reattaches
    Then UE ${DEFAULT_UE_ID} should have no leftover traffic after reattach
    And dedicated bearer used before detach should be removed for UE ${DEFAULT_UE_ID}

Aggregated_traffic_stats_match_sum_of_per_bearer_rx_bps_and_default_bearer_add_rejected
    [Documentation]    Verify that aggregated UE traffic equals the sum of per-bearer RX rates.
    [Tags]    positive    negative    bearer    traffic    stats

    Given UE ${DEFAULT_UE_ID} is attached with default and three dedicated bearers
    And UE ${DEFAULT_UE_ID} has traffic running on selected bearers
    When detailed traffic statistics are requested for UE ${DEFAULT_UE_ID}
    Then dedicated bearer without started traffic should report zero rate for UE ${DEFAULT_UE_ID}
    And total UE traffic should equal the sum of per-bearer traffic for UE ${DEFAULT_UE_ID}

# ==========================

# Tomek

Remove_default_bearer_rejected
    [Documentation]    Verify that removing default bearer (ID=9) is not allowed.
    [Tags]    negative    bearer    remove    validation

    ${ue_id}=    Set Variable    ${DEFAULT_UE_ID}

    Log    Step 1: Attach UE with default bearer
    Attach UE And Verify Default Bearer    ${ue_id}

    Log    Step 2: Attempt to remove default bearer
    ${response}=    Remove Bearer    ${ue_id}    ${DEFAULT_BEARER_ID} 

    Log    Step 3: Verify request is rejected
    Should Be Equal As Integers    ${response.status_code}    400

    Log    Step 5: Verify error message is returned
    Should Be Equal    ${response.json()}[detail]    Cannot remove default bearer

    Log    Step 6: Verify UE state remains unchanged
    Verify UE Does Not Exist    ${ue_id}

    Log    Step 7: Verify no bearers are affected
    ${stats_after}=    Get UE Stats
    Should Be Equal As Integers    ${stats_after}[ue_count]         ${stats_before}[ue_count]
    Should Be Equal As Integers    ${stats_after}[bearer_count]     ${stats_before}[bearer_count]
    Should Be Equal As Integers    ${stats_after}[total_tx_bps]     ${stats_before}[total_tx_bps]
    Should Be Equal As Integers    ${stats_after}[total_rx_bps]     ${stats_before}[total_rx_bps]


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

# ==========================

# Łukasz

Add_bearer_rejected_for_duplicate_bearer_id
    [Documentation]    Verify that adding the same bearer twice is rejected.
    [Tags]    negative    bearer    add

    Given UE ${DEFAULT_UE_ID} is attached with default bearer
    And UE ${DEFAULT_UE_ID} has dedicated bearer ${TEST_BEARER_ID}
    When attach duplicated bearer ${TEST_BEARER_ID} to UE ${DEFAULT_UE_ID}
    Then Attach request for UE ${DEFAULT_UE_ID} should be rejected
    And UE ${DEFAULT_UE_ID} should have bearer ${TEST_BEARER_ID}

Start_traffic_rejected_for_value_above_max_limit
    [Documentation]    Verify that traffic start is rejected when requested transfer exceeds maximum allowed limit (100 Mbps).
    [Tags]    negative    traffic    bearer    validation

    Given UE ${DEFAULT_UE_ID} is attached with default bearer    
    When start traffic is requested for ${DEFAULT_UE_ID} at ${DEFAULT_BEARER_ID} with ${TRANSFER_SPEED_ABOVE_LIMIT_MBPS} transfer speed
    Then start traffic operation for UE ${DEFAULT_UE_ID} at ${DEFAULT_BEARER_ID} should be rejected and traffic wasnt started

Attach_operation_on_already_attached_ue_error_scenario
    [Documentation]    Verify that attach operation is rejected for UE that is already attached to the network.
    [Tags]    negative    attach    ue
    
    Given UE ${DEFAULT_UE_ID} is attached with default bearer
    And current system statistics are captured
    When reattach UE ${DEFAULT_UE_ID} with default bearer
    Then attach request for UE ${DEFAULT_UE_ID} should be rejected with message UE already attached
    And UE ${DEFAULT_UE_ID} exists
