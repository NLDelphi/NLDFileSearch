object frmMain: TfrmMain
  Left = 202
  Top = 135
  Width = 434
  Height = 293
  Caption = 'NLDFileSearch Component Demo'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  DesignSize = (
    426
    266)
  PixelsPerInch = 96
  TextHeight = 13
  object lblMask: TLabel
    Left = 4
    Top = 8
    Width = 29
    Height = 13
    Caption = 'Mask:'
  end
  object cmdNormal: TButton
    Left = 4
    Top = 104
    Width = 137
    Height = 25
    Caption = '&Without ProcessMessages'
    TabOrder = 0
    OnClick = cmdNormalClick
  end
  object cmdProcessMessages: TButton
    Left = 4
    Top = 132
    Width = 137
    Height = 25
    Caption = 'With &ProcessMessages'
    TabOrder = 1
    OnClick = cmdProcessMessagesClick
  end
  object cmdUpdate: TButton
    Left = 4
    Top = 160
    Width = 137
    Height = 25
    Caption = 'With &BeginUpdate'
    TabOrder = 2
    OnClick = cmdUpdateClick
  end
  object lstFiles: TListBox
    Left = 148
    Top = 4
    Width = 273
    Height = 257
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 13
    TabOrder = 3
  end
  object txtMask: TEdit
    Left = 40
    Top = 4
    Width = 101
    Height = 21
    TabOrder = 4
    Text = '*.exe'
  end
  object chkRecursive: TCheckBox
    Left = 4
    Top = 32
    Width = 137
    Height = 17
    Caption = 'Process &subdirectories'
    Checked = True
    State = cbChecked
    TabOrder = 5
  end
  object chkRelative: TCheckBox
    Left = 4
    Top = 52
    Width = 137
    Height = 17
    Caption = '&Relative paths'
    Checked = True
    State = cbChecked
    TabOrder = 6
  end
  object cmdCancel: TButton
    Left = 4
    Top = 236
    Width = 137
    Height = 25
    Cancel = True
    Caption = '&Cancel'
    Enabled = False
    TabOrder = 7
    OnClick = cmdCancelClick
  end
  object chkIgnoreDirs: TCheckBox
    Left = 4
    Top = 72
    Width = 137
    Height = 17
    Caption = 'Do not list &directories'
    Checked = True
    State = cbChecked
    TabOrder = 8
  end
  object fsSearch: TNLDStringsFileSearch
    Mask = '*.exe'
    Options = [soRecursive]
    Left = 4
    Top = 188
  end
end
