*** Settings ***
Documentation       Certificate Level 2

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Images
Library             RPA.Desktop
Library             OperatingSystem
Library             RPA.Email.Exchange
Library             RPA.Archive


*** Variables ***
${popup_button}=            xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
${legs_input}=              xpath://*[@id="root"]/div/div[1]/div/div[1]/form/div[3]/input
${PDF_Files_Path} =         ${CURDIR}/output/PDF_Files
${IMAGE_Files_Path} =       ${CURDIR}/output/IMAGE_Files
${store_url}=               https://robotsparebinindustries.com/#/robot-order
${csv_endpoint}=            https://robotsparebinindustries.com/orders.csv


*** Tasks ***
Level 2
    Download the Csv file
    Create Dirs
    Open Store Page
    LoopCSV
    Zip the pdflist


*** Keywords ***
Create Dirs
    Create Directory    ${PDF_Files_Path}
    Create Directory    ${IMAGE_Files_Path}

Download the Csv file
    Download    ${csv_endpoint}    ${CURDIR}/output    overwrite=True

LoopCSV
    ${csv_data}=    Read table from CSV    ${CURDIR}/output/orders.csv
    FOR    ${current_row}    IN    @{csv_data}
        Log    ${current_row}
        Enter Single Row    ${current_row}
    END
    Close Browser

Open Store Page
    Open Available Browser    ${store_url}
    Maximize Browser Window

Enter Single Row
    [Arguments]    ${row}
    Wait Until Element Is Visible    ${popup_button}    2s
    Run Keyword And Ignore Error    Click Element    ${popup_button}
    Wait Until Element Is Visible    id:head
    Select From List By Value    id:head    ${row}[Head]
    Click Element    id:id-body-${row}[Body]
    Input Text    ${legs_input}    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    Click Element    id:preview
    Click Element    id:order
    Sleep    1s
    ${count}=    Run Keyword And Return Status    Page Should Contain Element    css:div[class="alert alert-danger"]
    IF    ${count}
        Reload Page
        # Log To Console    Order Number: ${row}[Order number] is failed
    ELSE
        ${robot_screenshot}=    Take Preview ScreenShot    ${row}[Order number]
        ${robot_receipt}=    Download Order receipt    ${row}[Order number]
        image and receipt embed    ${robot_receipt}    ${robot_screenshot}
        Wait Until Element Is Visible    id:order-another    2s
        Click Element    id:order-another
    END

Take Preview ScreenShot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${IMAGE_Files_Path}${/}${order_number}.PNG
    RETURN    ${IMAGE_Files_Path}${/}${order_number}.PNG

Download Order receipt
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_outher_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_outher_html}    ${PDF_Files_Path}${/}receipt_${order_number}.pdf
    RETURN    ${PDF_Files_Path}${/}receipt_${order_number}.pdf

image and receipt embed
    [Arguments]    ${receipt_pdf}    ${robot_image}
    Open Pdf    ${receipt_pdf}
    @{pdflist}=    Create List    ${robot_image}
    Log To Console    ${pdflist}${SPACE}${pdflist}[0]
    Add Watermark Image To Pdf    ${robot_image}    ${receipt_pdf}
    # Add Files To Pdf    ${pdflist}    ${receipt_pdf}    ${True}
    Close Pdf    ${receipt_pdf}

Zip the pdflist
    Archive Folder With Zip    ${PDF_Files_Path}    ${CURDIR}/output/PDF_receipts.zip
