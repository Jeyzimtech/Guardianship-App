"""Add print-only OOXML metadata unavailable in artifact-tool's public API.
All cells, formulas, styles, tables and validations are authored by artifact-tool.
"""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import json
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[2]
file = root / 'output' / 'EduConnect UVT Test Script.xlsx'
ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'
q = lambda tag: '{'+ns+'}'+tag
ET.register_namespace('', ns)
with ZipFile(file) as z:
    files = {n:z.read(n) for n in z.namelist()}
book=ET.fromstring(files['xl/workbook.xml'])
sheets=book.find(q('sheets'))
assert [s.attrib['name'] for s in sheets] == ['Read Me','Test Data','Test Cases','Summary','Issues Log','Client Sign-off']
defined=book.find(q('definedNames'))
if defined is None:
    defined=ET.Element(q('definedNames'))
    index=list(book).index(sheets)+1
    book.insert(index,defined)
for existing in list(defined):
    if existing.attrib.get('name') in ['_xlnm.Print_Area','_xlnm.Print_Titles']:defined.remove(existing)
ends=['B23','B33','N204','J28','O54','B21']
for i,s in enumerate(sheets):
    name=s.attrib['name']; key=f'xl/worksheets/sheet{i+1}.xml'
    sheet=ET.fromstring(files[key])
    # Attach sheetPr before dimension/views as prescribed by SpreadsheetML order.
    prop=sheet.find(q('sheetPr'))
    if prop is None:prop=ET.Element(q('sheetPr'));sheet.insert(0,prop)
    setuppr=prop.find(q('pageSetUpPr'))
    if setuppr is None:setuppr=ET.SubElement(prop,q('pageSetUpPr'))
    setuppr.set('fitToPage','1')
    # Insert page metadata before tableParts and other later worksheet elements.
    later={'headerFooter','rowBreaks','colBreaks','customProperties','cellWatches','ignoredErrors','smartTags','drawing','legacyDrawing','legacyDrawingHF','picture','oleObjects','controls','webPublishItems','tableParts','extLst'}
    def append_ordered(element):
        for j,item in enumerate(sheet):
            if item.tag.split('}')[-1] in later:
                sheet.insert(j,element); return
        sheet.append(element)
    margins=ET.Element(q('pageMargins'),left='0.25',right='0.25',top='0.5',bottom='0.5',header='0.2',footer='0.2')
    setup=ET.Element(q('pageSetup'),orientation='landscape',paperSize='8' if i in (2,4) else '9',fitToWidth='1',fitToHeight='0')
    for tag in ('pageMargins','pageSetup'):
        old=sheet.find(q(tag))
        if old is not None:sheet.remove(old)
    append_ordered(margins);append_ordered(setup)
    footer=ET.Element(q('headerFooter'))
    ET.SubElement(footer,q('oddFooter')).text='&LEduConnect UVT | v1.0&C'+name+'&RPage &P of &N'
    old=sheet.find(q('headerFooter'))
    if old is not None:sheet.remove(old)
    append_ordered(footer)
    col=''.join(c for c in ends[i] if c.isalpha());row=''.join(c for c in ends[i] if c.isdigit())
    ET.SubElement(defined,q('definedName'),name='_xlnm.Print_Area',localSheetId=str(i)).text=f"'{name}'!$A$1:${col}${row}"
    ET.SubElement(defined,q('definedName'),name='_xlnm.Print_Titles',localSheetId=str(i)).text=f"'{name}'!$4:$4"
    files[key]=ET.tostring(sheet,encoding='utf-8',xml_declaration=True)
    cells=sheet.findall('.//'+q('c'))
    assert not [c for c in cells if c.attrib.get('t')=='e'],name
    print(name,'cells',len(cells),'formulas',len(sheet.findall('.//'+q('f'))),'validations',len(sheet.findall('.//'+q('dataValidation'))))
files['xl/workbook.xml']=ET.tostring(book,encoding='utf-8',xml_declaration=True)
temp=file.with_suffix('.tmp.xlsx')
with ZipFile(temp,'w',ZIP_DEFLATED) as z:
    for name,content in files.items():z.writestr(name,content)
temp.replace(file)
with ZipFile(file) as z:
    assert z.testzip() is None
    for name in z.namelist():
        if name.endswith('.xml'):ET.fromstring(z.read(name))
    for name in ['xl/tables/table1.xml','xl/tables/table2.xml']:
        t=ET.fromstring(z.read(name));print('Filter table',t.attrib['ref'])
print('Verified',file.name,file.stat().st_size,'bytes')
