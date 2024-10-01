// @ts-check
import 'jszip';
import JSZip from 'jszip';
/** @param {MessageEvent<{fileContent: String, fileName: String}>} event */
onmessage = async (event) => {
    const zip = new JSZip();
    const textContent = event.data.fileContent;
    const fileName = event.data.fileName;

    zip.file(fileName, textContent);
    const compressed = await zip.generateAsync({
        type: "base64",
        compression: "DEFLATE",
        compressionOptions: {
            level: 9
        },
    });
    postMessage(compressed);
};