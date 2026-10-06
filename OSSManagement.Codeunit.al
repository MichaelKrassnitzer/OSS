codeunit 61000 "OSS Management"
{
    // OSS001  30.06.2021 FS  One-Stop-Shop process
    // OSS002  30.03.2022 MK  Added Code to UpdateShipToAddress
    // OSS003  08.11.2022 MK  Changed Code to not update Posting Groups when they are filled
    // Migriert aus C/AL-Änderungen in Table 36 "Sales Header" auf Event-Subscriber.

    SingleInstance = true;

    var
        SellToBuffer: Record "Sales Header" temporary;
        BillToBuffer: Record "Sales Header" temporary;

    // ++ OSS001
    procedure CheckOSSSetup(var SalesHeader: Record "Sales Header")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        Cust: Record Customer;
        UseBusPostGrp: Code[20];
        UseVATPostGrp: Code[20];
        DocumentDate: Date;
    begin
        SalesSetup.Get();
        DocumentDate := SalesHeader."Document Date";
        if SalesHeader."Posting Date" <> 0D then
            DocumentDate := SalesHeader."Posting Date";

        if not SalesSetup."OSS Active" or (DocumentDate < SalesSetup."OSS Activation Date") then
            exit;

        CompanyInfo.Get();
        if SalesHeader."Ship-to Country/Region Code" in ['', CompanyInfo."Country/Region Code"] then begin
            Cust.Get(SalesHeader."Bill-to Customer No.");
            UseBusPostGrp := Cust."Gen. Bus. Posting Group";
            UseVATPostGrp := Cust."VAT Bus. Posting Group";
        end else begin
            if (SalesHeader."VAT Registration No." <> '') or
               not Country.Get(SalesHeader."Ship-to Country/Region Code") or
               (Country."EU Country/Region Code" = '')
            then
                exit;

            SalesSetup.TestField("OSS Post.Grp Template");
            UseBusPostGrp := CopyStr(StrSubstNo(SalesSetup."OSS Post.Grp Template", Country."EU Country/Region Code"), 1, MaxStrLen(UseBusPostGrp));
            UseVATPostGrp := CopyStr(StrSubstNo(SalesSetup."OSS Post.Grp Template", Country."EU Country/Region Code"), 1, MaxStrLen(UseVATPostGrp));
        end;

        if SalesHeader."Gen. Bus. Posting Group" <> UseBusPostGrp then
            SalesHeader.Validate("Gen. Bus. Posting Group", UseBusPostGrp);
        if SalesHeader."VAT Bus. Posting Group" <> UseVATPostGrp then
            SalesHeader.Validate("VAT Bus. Posting Group", UseVATPostGrp);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Ship-to Country/Region Code', false, false)]
    local procedure OnAfterValidateShipToCountry(var Rec: Record "Sales Header")
    begin
        if Rec.IsTemporary() then
            exit;
        CheckOSSSetup(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Posting Date', false, false)]
    local procedure OnAfterValidatePostingDate(var Rec: Record "Sales Header")
    begin
        // C/AL: VALIDATE("Ship-to Country/Region Code") am Ende des Posting-Date-Triggers
        if Rec.IsTemporary() then
            exit;
        CheckOSSSetup(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'VAT Registration No.', false, false)]
    local procedure OnAfterValidateVATRegistrationNo(var Rec: Record "Sales Header"; var xRec: Record "Sales Header")
    begin
        if Rec.IsTemporary() then
            exit;
        if Rec."VAT Registration No." = xRec."VAT Registration No." then
            exit;
        CheckOSSSetup(Rec);
    end;
    // -- OSS001

    // ++ OSS002
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterUpdateShipToAddress', '', false, false)]
    local procedure OnAfterUpdateShipToAddress(var SalesHeader: Record "Sales Header")
    begin
        if SalesHeader.IsCreditDocType() then
            if SalesHeader."VAT Registration No." = '' then
                SalesHeader."Ship-to Country/Region Code" := SalesHeader."Bill-to Country/Region Code";
    end;
    // -- OSS002

    // ++ OSS003
    // Bereits gefüllte Buchungsgruppen werden beim Übernehmen der Debitorfelder nicht überschrieben.
    // Die Werte vor der Validierung werden gemerkt und nach dem Kopieren der Debitorfelder wiederhergestellt.
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateEvent', 'Sell-to Customer No.', false, false)]
    local procedure OnBeforeValidateSellToCustomerNo(var Rec: Record "Sales Header")
    begin
        Remember(SellToBuffer, Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Sell-to Customer No.', false, false)]
    local procedure OnAfterValidateSellToCustomerNo()
    begin
        SellToBuffer.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterCopySellToCustomerAddressFieldsFromCustomer', '', false, false)]
    local procedure OnAfterCopySellToCustomerAddressFieldsFromCustomer(var SalesHeader: Record "Sales Header")
    begin
        RestoreFilledPostingGroups(SellToBuffer, SalesHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidateEvent', 'Bill-to Customer No.', false, false)]
    local procedure OnBeforeValidateBillToCustomerNo(var Rec: Record "Sales Header")
    begin
        Remember(BillToBuffer, Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Bill-to Customer No.', false, false)]
    local procedure OnAfterValidateBillToCustomerNo()
    begin
        BillToBuffer.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterSetFieldsBilltoCustomer', '', false, false)]
    local procedure OnAfterSetFieldsBilltoCustomer(var SalesHeader: Record "Sales Header")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if GLSetup."Bill-to/Sell-to VAT Calc." <> GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No." then
            exit;
        RestoreFilledPostingGroups(BillToBuffer, SalesHeader);
    end;

    local procedure Remember(var Buffer: Record "Sales Header" temporary; SalesHeader: Record "Sales Header")
    begin
        Buffer.DeleteAll();
        if SalesHeader.IsTemporary() then
            exit;
        Buffer."Document Type" := SalesHeader."Document Type";
        Buffer."No." := SalesHeader."No.";
        Buffer."Gen. Bus. Posting Group" := SalesHeader."Gen. Bus. Posting Group";
        Buffer."VAT Bus. Posting Group" := SalesHeader."VAT Bus. Posting Group";
        Buffer.Insert();
    end;

    local procedure RestoreFilledPostingGroups(var Buffer: Record "Sales Header" temporary; var SalesHeader: Record "Sales Header")
    begin
        if not Buffer.Get(SalesHeader."Document Type", SalesHeader."No.") then
            exit;
        if Buffer."Gen. Bus. Posting Group" <> '' then
            SalesHeader."Gen. Bus. Posting Group" := Buffer."Gen. Bus. Posting Group";
        if Buffer."VAT Bus. Posting Group" <> '' then
            SalesHeader."VAT Bus. Posting Group" := Buffer."VAT Bus. Posting Group";
    end;
    // -- OSS003
}
