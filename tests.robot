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


Detach_clears_bearer_traffic_state_no_ghost_traffic_after_reattach
    [Documentation]    Verify that detach clears bearer traffic state and no ghost traffic appears after UE reattach.
    [Tags]    negative    attach    detach    bearer    traffic    state

    Reset Simulator
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

    Reset Simulator
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
