*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}    run_on_failure=${NONE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orders}=    Get orders

    Open the robot order website

    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    5x    3 sec    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Wait Until Keyword Succeeds    5x    3 sec    Go to order another robot
    END

    Create a ZIP file of the receipts


*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    credentials
    Open Available Browser    ${secret}[order_url]

Get orders
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    Add text input    message    placeholder=URL of the orders CSV file
    ${result}=    Run dialog
    Download    ${result.message}    overwrite=True
    ${table}=    Read table from CSV    orders.csv
    RETURN    ${table}

Close the annoying modal
    Wait Until Element Is Visible    css:div.alert-buttons    300 sec
    Click Button    OK

Fill the form
    [Arguments]    ${robot}
    Select From List By Value    head    ${robot}[Head]
    Select Radio Button    body    ${robot}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${robot}[Legs]
    Input Text    address    ${robot}[Address]

Preview the robot
    Click Button    Preview

Submit the order
    Click Button    Order

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:order-completion    300 sec
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts${/}receipt_${order_number}.pdf
    RETURN    ${OUTPUT_DIR}${/}receipts${/}receipt_${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    css:img[alt="Legs"]    60 sec
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}screenshots${/}robot_${order_number}.png
    RETURN    ${OUTPUT_DIR}${/}screenshots${/}robot_${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List    ${pdf}:1    ${screenshot}:align=center
    Add Files To PDF    ${files}    ${pdf}

Go to order another robot
    Click Button    Order another robot

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.zip
