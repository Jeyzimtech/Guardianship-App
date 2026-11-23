import fs from 'node:fs/promises';
import {FileBlob, SpreadsheetFile} from '@oai/artifact-tool';
const wb = await SpreadsheetFile.importXlsx(await FileBlob.load('Seed Co Zimbabwe - Roadrunner UVT Test Script.xlsx'));
console.log((await wb.inspect({kind:'sheet',include:'id,name',maxChars:1200})).ndjson);
for (const name of ['Read Me','Client Sign-off']) console.log(name,JSON.stringify(wb.worksheets.getItem(name).getUsedRange().values));
console.log((await wb.inspect({kind:'computedStyle',sheetId:'Test Cases',range:'A4:H5',maxChars:2200})).ndjson);
await fs.writeFile('output/uvt_work/reference.png',new Uint8Array(await (await wb.render({sheetName:'Read Me',range:'A1:B10',scale:1,format:'png'})).arrayBuffer()));
