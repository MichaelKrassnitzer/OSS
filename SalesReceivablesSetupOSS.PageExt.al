pageextension 61000 "Sales & Receivables Setup OSS" extends "Sales & Receivables Setup"
{
    layout
    {
        addlast(content)
        {
            group(OSSSetup)
            {
                Caption = 'OSS Setup', Comment = 'DEA="OSS Einrichtung"';

                field("OSS Active"; Rec."OSS Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the One-Stop-Shop process is active.';
                }
                field("OSS Post.Grp Template"; Rec."OSS Post.Grp Template")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the template for the OSS posting groups, e.g. OSS-%1. %1 is replaced by the EU country/region code of the ship-to country.';
                }
                field("OSS Activation Date"; Rec."OSS Activation Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies from which posting/document date on the OSS process is applied.';
                }
            }
        }
    }
}
