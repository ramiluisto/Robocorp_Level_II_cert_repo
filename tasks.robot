*** Settings ***
Documentation       Rami's version of the automation for the Robocorp
...                 Level 2 cert.
...
...                 Current issues:
...                 1. Throws warnings related to "Overwriting cache for 0 xx" and
...                 "Object X Y found" during pdf creation. Also in pdf, the image is on
...                 a second page and not right after html output, sry.
...                 2. Many of the filepaths should be set to conf variables and not repeated
...                 literal strings.
...
...                 "Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images."

Library             RPA.Browser.Selenium    auto_close=${FALSE }
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             OperatingSystem


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order site
    Accept terms
    Download the order data
    Make the order based on the data
    Archive the results
    [Teardown]    Clear folders and close Browser


*** Keywords ***
Open the robot order site
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Accept terms
    Wait Until Element Is Visible    css:div.modal-dialog
    Click Button    OK

Download the order data
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Make the order based on the data
    ${orders}=    Read table from CSV    orders.csv
    Log    Found columns {orders.columns}

    FOR    ${order_row}    IN    @{orders}
        Log    Doing order number ${order_row}[Order number]
        Make one order    ${order_row}
    END

Make one order
    [Arguments]    ${order_row}
    TRY
        Accept terms
    EXCEPT
        Log    no terms to accept
    END

    Select From List By Value    id:head    ${order_row}[Head]
    Select Radio Button    body    ${order_row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order_row}[Legs]
    Input Text    id:address    ${order_row}[Address]

    Click Button    preview
    Screenshot
    ...    robot-preview-image
    ...    ${OUTPUT_DIR}${/}preview_images${/}order_${order_row}[Order number]_preview.png

    Wait Until Keyword Succeeds    10x    0.5s    Try to make the order    ${order_row}

Try to make the order
    [Arguments]    ${order_row}

    Click Button    order
    Create the receipt PDF    ${order_row}
    Click Button    order-another

Create the receipt PDF
    [Arguments]    ${order_row}

    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipt_pdfs${/}order_no_${order_row}[Order number].pdf

    ${receipt_and_image}=    Create List
    ...    ${OUTPUT_DIR}${/}receipt_pdfs${/}order_no_${order_row}[Order number].pdf
    ...    ${OUTPUT_DIR}${/}preview_images${/}order_${order_row}[Order number]_preview.png:x=0,y=0

    Add Files To Pdf
    ...    ${receipt_and_image}
    ...    ${OUTPUT_DIR}${/}receipt_pdfs${/}order_no_${order_row}[Order number].pdf

Archive the results
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipt_pdfs    ${OUTPUT_DIR}${/}Orders.zip

Clear folders and close Browser
    Close Browser
    Remove Directory    ${OUTPUT_DIR}${/}receipt_pdfs    recursive=${True}
    Remove Directory    ${OUTPUT_DIR}${/}preview_images    recursive=${True}
