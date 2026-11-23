import {Workbook} from '@oai/artifact-tool';
const w=Workbook.create();
console.log(w.help('print settings',{search:'print|pageSetup|pageLayout',include:'index,examples,notes',maxChars:3000}).ndjson);
