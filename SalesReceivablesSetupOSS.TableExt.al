tableextension 61000 "Sales & Receivables Setup OSS" extends "Sales & Receivables Setup"
{
    // OSS001 05.07.2021 FS New Fields

    fields
    {
        field(61000; "OSS Active"; Boolean)
        {
            Caption = 'OSS Active', Comment = 'DEA="OSS Aktiv"';
            DataClassification = CustomerContent;
        }
        field(61001; "OSS Post.Grp Template"; Code[10])
        {
            Caption = 'OSS Posting Groups Template', Comment = 'DEA="OSS Buchungsgruppen Gruppen Vorlage"';
            DataClassification = CustomerContent;
        }
        field(61002; "OSS Activation Date"; Date)
        {
            Caption = 'OSS Activation Date', Comment = 'DEA="OSS Aktivierungsdatum"';
            DataClassification = CustomerContent;
        }
    }
}
