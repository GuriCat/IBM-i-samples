Option Explicit

Dim inbuf, tfrOpt, DBCSVPath, DBFFDPath, outXLSX, convDateTimeDec, convDateTimeChr As String
Dim params As Variant
Dim maxRow, maxCol, cellValue As Long
Dim dtFormula As String
Dim ThisBook As Workbook
Dim ThisSheet As Worksheet
Dim i, j As Long

Private Sub Workbook_Open()

    Call main

End Sub

Sub main()

    ' �e�L�X�g�t�@�C������p�����[�^�[�̓ǂݍ���
    With CreateObject("Scripting.FileSystemObject")
        With .GetFile(Environ("TEMP") & "\DB2EXCEL_PARAM.TXT").OpenAsTextStream
            inbuf = .ReadAll
            .Close
        End With
    End With
    Kill Environ("TEMP") & "\DB2EXCEL_PARAM.TXT"

    params = Split(inbuf, vbLf) ' ���s�R�[�h��LF��z��
    If UBound(params) < 6 Then
        MsgBox "IBM i ����̃p�����[�^�[�����Ȃ�", vbCritical, "DB2EXCEL�G���["
        Workbooks("DB2EXCEL.xlsm").Close
    End If

    ' �p�����[�^�[�t�@�C���̎w�����荞��
    tfrOpt = params(0) ' N:NetServer�AF:FTP
    DBCSVPath = params(1)
    DBFFDPath = params(2)
    If tfrOpt = "F" Then
        DBCSVPath = Environ("TEMP") & "\" & Mid(params(1), InStrRev(params(1), "\") + 1)
        DBFFDPath = Environ("TEMP") & "\" & Mid(params(2), InStrRev(params(2), "\") + 1)
    End If
    outXLSX = params(3)
    convDateTimeDec = params(4) ' ���t�E�����t�B�[���h�̐����ƃt�H�[�}�b�g(���l�t�B�[���h)
    convDateTimeChr = params(5) ' ���t�E�����t�B�[���h�̐����ƃt�H�[�}�b�g(�����t�B�[���h)
    If DBCSVPath = "" Or DBFFDPath = "" Then
        MsgBox "IBM i ����̎w�肳�ꂽ�p�X���󕶎�", vbCritical, "DB2EXCEL�G���["
        Workbooks("DB2EXCEL.xlsm").Close
    End If

    ' CSV�t�@�C���̓ǂݍ��݂�Excel�u�b�N�̍쐬
    genExcel

    ' Move new worksheets to new book
    ' Sheets(Array("DB�Ɖ��", "�t�B�[���h�L�q")).Move ' �Ȃ����ƂĂ��x��
    Sheets(Array("DB�Ɖ��", "�t�B�[���h�L�q")).Copy

    ' �L���v�V�����̐ݒ�
    ActiveWindow.Caption = outXLSX
    ' Excel�u�b�N�̃N���[�Y
    Application.DisplayAlerts = False
    Workbooks("DB2EXCEL.xlsm").Close

End Sub

' Create new Excel book

Sub genExcel()

    Dim colHdg, fldColHdgAry() As String
    Dim fldLengthAry(), fldDigitAry(), fldPrecAry() As Integer
    Dim colTypeAry() As Variant

    ' ���݂��郏�[�N�V�[�g�̍Ō���ɐV�������[�N�V�[�g��}��
    Application.SheetsInNewWorkbook = 3
    Workbooks("DB2EXCEL.xlsm").Activate
    Worksheets.Add after:=Worksheets(Worksheets.Count)
    ActiveSheet.Name = "DB�Ɖ��"
    Worksheets.Add after:=Worksheets(Worksheets.Count)
    ActiveSheet.Name = "�t�B�[���h�L�q"

    ' FFD�f�[�^��CSV�t�@�C���̓ǂݍ���
    Worksheets("�t�B�[���h�L�q").Activate

    With ActiveSheet.QueryTables.Add(Connection:="TEXT;" _
        & DBFFDPath, Destination:=ActiveSheet.Range("A2"))

        ' .AdjustColumnWidth = True
        .TextFileCommaDelimiter = True
        .TextFileParseType = xlDelimited
        .TextFileTextQualifier = xlTextQualifierDoubleQuote
        .Refresh BackgroundQuery:=False
        .Delete

    End With

    ' FFD�V�[�g�̃t�H�[�}�b�g
    With ActiveSheet

        ' DSPFFD�o�̓t�@�C���̕s�v�ȃt�B�[���h������
        .Range("BE1:CX1").EntireColumn.Delete
        .Range("AC1:BC1").EntireColumn.Delete
        .Range("A1:I1").EntireColumn.Delete

        maxCol = ActiveSheet.Range("A2").Value

        ' �t�B�[���h������z��ɃZ�b�g
        ReDim fldLengthAry(maxCol)
        ReDim fldDigitAry(maxCol)
        ReDim fldPrecAry(maxCol)
        ReDim fldColHdgAry(maxCol)
        ReDim colTypeAry(maxCol)

        For i = 0 To maxCol
            ' Field length
            fldLengthAry(i) = .Cells(i + 2, 7).Value ' �t�B�[���h��
            ' Digit and precision
            fldDigitAry(i) = .Cells(i + 2, 8).Value ' ���l����
            fldPrecAry(i) = .Cells(i + 2, 9).Value  ' �����_����
            ' Column heading
            colHdg = .Cells(i + 2, 16).Value & _
                .Cells(i + 2, 17).Value & .Cells(i + 2, 18).Value
            fldColHdgAry(i) = Replace(Replace(colHdg, " ", ""), "�@", "")
            ' Use field name when colhdg is blank
            If fldColHdgAry(i) = "" Then
                fldColHdgAry(i) = .Cells(i + 2, 4).Value ' �O���t�B�[���h��
            End If
            ' QueryTable.TextFileColumnDataTypes�̃v���p�e�B���Z�b�g
            If fldDigitAry(i) > 0 Then
                colTypeAry(i) = xlGeneralFormat
            Else
                colTypeAry(i) = xlTextFormat
            End If
        Next i

        ' �Q�l�Ƃ��ăZ��A1��library_file�����Z�b�g
        .Range("A1").Offset(.Range("A2").Value + 2).Value = outXLSX

        ' ���o���̐ݒ�
        .Range("A1:T1").Value = Array( _
            "�t�B�[���h��", "���R�[�h�l����", "�����t�B�[���h��", _
            "�O���t�B�[���h��", "�o�̓o�b�t�@�[�ʒu", "���̓o�b�t�@�[�ʒu", _
            "�t�B�[���h���\�o�C�g��", "����", "�����_�̉E���̌���", _
            "�t�B�[���h�E�e�L�X�g�L�q", "REF �̘a", "�Q�ƃt�@�C��", _
            "�Q�ƃ��C�u�����[", "�Q�ƃ��R�[�h�l��", "�Q�ƃt�B�[���h", _
            "�J�������o�� 1", "�J�������o�� 2", "�J�������o�� 3", _
            "�t�B�[���h�^�C�v", "�R�[�h�������Z�b�g ID")

        ' ���[�N�V�[�g���t�H�[�}�b�g
        .Range("A2").Select
        ActiveWindow.FreezePanes = True     ' �w�b�_�[�̌Œ�
        ActiveWindow.Zoom = 80              ' �g�嗦�̐ݒ�

    End With

    ' �e�[�u���̒�` object.Add ( [ sourcetype, source, linksource, xllistobjecthasheaders, destination, tablestylename ] )
    With ActiveSheet.ListObjects.Add(, , , xllistobjecthasheaders:=xlYes)
        .Name = "�t�@�C���t�B�[���h�L�q"
        .TableStyle = "TableStyleLight14"
    End With
    ' �񕝎�������
    ActiveSheet.ListObjects("�t�@�C���t�B�[���h�L�q").Range.Columns.AutoFit

    ' �����t�@�C����CSV�t�@�C���ǂݍ���
    Worksheets("DB�Ɖ��").Activate

    With ActiveSheet.QueryTables.Add(Connection:="TEXT;" _
        & DBCSVPath, Destination:=ActiveSheet.Range("A2"))

        ' .AdjustColumnWidth = True
        .TextFileCommaDelimiter = True
        .TextFileParseType = xlDelimited
        .TextFileTextQualifier = xlTextQualifierDoubleQuote
        .TextFileColumnDataTypes = colTypeAry
        .Refresh BackgroundQuery:=False
        .Delete

    End With

    Application.Calculation = xlCalculationManual '�蓮�v�Z
    Application.ScreenUpdating = False '��ʍX�V��~

    ' DB�Ɖ�o�͂̃��[�N�V�[�g���t�H�[�}�b�g
    With ActiveSheet

        maxRow = .Range("A1").SpecialCells(xlLastCell).Row

        ' FFD�V�[�g���Q�Ƃ��ė����o�����Z�b�g
        For i = 0 To maxCol - 1
            .Range("A1").Offset(0, i).NumberFormat = "@"
            .Range("A1").Offset(0, i).Value = RTrim(fldColHdgAry(i))
            ' ���l�t�B�[���h�ɃJ���}���w��
            ' If (fldDigitAry(i) <> 6) And (fldDigitAry(i) <> 8) Then
                If fldPrecAry(i) = 0 Then
                    .Columns(i + 1).NumberFormat = "#,##0"
                Else
                    .Columns(i + 1).NumberFormat = "#,##0." _
                    & String(fldPrecAry(i), "0")
                End If
            ' End If
        Next i

        ' ���t�E�����t�B�[���h�̐����ƃt�H�[�}�b�g(���l�t�B�[���h)
        If UCase(convDateTimeDec) = "Y" Then

            ' �J�����̑������`�F�b�N
            For i = 0 To maxCol - 1
                ' ColHdg���u���v�Ƃ����������܂݁A���A������8��6 �� ���t
                If (fldColHdgAry(i) Like "*��*") And ((fldDigitAry(i) = 8) Or _
                   (fldDigitAry(i) = 6)) Then
                    .Columns(i + 1).NumberFormatLocal = "yyyy/mm/dd"
                    For j = 2 To maxRow
                        ' Excel�͐��l��6���ł��N4���ɕϊ�
                        ' �Z���ɓ����Ă���l�������ɖ��֌W�Ɏ擾���邽�� .value2 ���g�p�B(overflow �G���[���)
                        cellValue = .Range(Cells(j, i + 1).Address(False, False)).Value2
                        dtFormula = _
                            "=IF(ISERROR(DATEVALUE(TEXT(" & cellValue & _
                            ",""00!/00!/00""))),TEXT(" & cellValue & _
                            ",""@""),DATEVALUE(TEXT(" & cellValue & ",""00!/00!/00"")))"
                        .Range(Cells(j, i + 1).Address).Formula = dtFormula
                    Next j
                End If
                ' ColHdg���u���v�Ƃ����������܂�Łu���v���܂܂��A���A������6 �� ����
                If (fldColHdgAry(i) Like "*��*") And (Not fldColHdgAry(i) Like "*��*") And _
                   (fldDigitAry(i) = 6) Then
                    .Columns(i + 1).NumberFormatLocal = "hh:mm:ss"
                    For j = 2 To maxRow
                        cellValue = .Range(Cells(j, i + 1).Address(False, False)).Value2
                        dtFormula = _
                            "=IF(ISERROR(TIMEVALUE(TEXT(" & cellValue & _
                            ",""00!:00!:00""))),TEXT(" & cellValue & _
                            ",""@""),TIMEVALUE(TEXT(" & cellValue & ",""00!:00!:00"")))"
                        .Range(Cells(j, i + 1).Address).Formula = dtFormula
                    Next j
                End If
            Next i

        End If

        ' ���t�E�����t�B�[���h�̐����ƃt�H�[�}�b�g(�����t�B�[���h)
        If UCase(convDateTimeChr) = "Y" Then
            ' �J�����̑������`�F�b�N
            For i = 0 To maxCol - 1
                ' ���t��ymd�Admy�Amdy�Ȃǂ�����ł��Ȃ��̂ŕۗ�
                ' ColHdg���u���v�Ƃ����������܂�Łu���v���܂܂��A���A������6 �� ����
                If (fldColHdgAry(i) Like "*��*") And (Not fldColHdgAry(i) Like "*��*") And _
                    (fldLengthAry(i) = 6) And (fldDigitAry(i) = 0) Then
                    .Columns(i + 1).NumberFormatLocal = "hh:mm:ss"
                    For j = 2 To maxRow
                        cellValue = .Range(Cells(j, i + 1).Address(False, False)).Value2
                        dtFormula = _
                            "=IF(ISERROR(TIMEVALUE(TEXT(" & cellValue & _
                            ",""00!:00!:00""))),TEXT(" & cellValue & _
                            ",""@""),TIMEVALUE(TEXT(" & cellValue & ",""00!:00!:00"")))"
                        .Range(Cells(j, i + 1).Address).Formula = dtFormula
                    Next j
                End If
            Next i
        End If

        With .PageSetup         ' �y�[�W�̃Z�b�g
            .Zoom = False
            .FitToPagesTall = False
            .FitToPagesWide = 1
        End With
        ActiveWindow.View = xlPageBreakPreview

        ' ���[�N�V�[�g�̃t�H�[�}�b�g
        .Range("A2").Select
        ActiveWindow.FreezePanes = True     ' �w�b�_�[�̌Œ�
        ActiveWindow.Zoom = 80              ' �g�嗦�̐ݒ�

    End With

    ' �e�[�u���̒�`
    With ActiveSheet.ListObjects.Add(, , , xllistobjecthasheaders:=xlYes)
        .Name = "�f�[�^�x�[�X��������"
        .TableStyle = "TableStyleMedium2"
    End With

    ' �s���E�񕝒���
    ' ActiveSheet.ListObjects("�f�[�^�x�[�X��������").DataBodyRange.Rows.RowHeight = 13
    ' ActiveSheet.ListObjects("�f�[�^�x�[�X��������").DataBodyRange.Columns.AutoFit
    For i = 1 To maxCol + 1
        Columns(i).ColumnWidth = Columns(i).ColumnWidth + 2
    Next i
    Cells.EntireRow.RowHeight = 13 ' �Ȃ����r���̍s����s�����L���Ȃ邽��...

    Application.Calculation = xlCalculationAutomatic '�����v�Z
    Application.ScreenUpdating = True '��ʍX�V�ĊJ

End Sub