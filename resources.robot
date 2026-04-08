*** Settings ***
Library    RequestsLibrary
Library    Collections

*** Variables ***
${BASE_URL}       http://127.0.0.1:8000
${SESSION}        epc
${DEFAULT_UE_ID}  10


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