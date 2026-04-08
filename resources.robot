*** Settings ***
Library    RequestsLibrary
Library    Collections

*** Variables ***
${BASE_URL}       http://127.0.0.1:8000
${DEFAULT_UE_ID}    10

*** Keywords ***
Create Api Session
Reset Simulator
Get UE
Get UE List
Get UE Stats
Attach UE
Detach UE
Verify UE Does Not Exist
Verify UE Exists
Verify Stats Are Zero
Verify Clean State