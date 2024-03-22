// @ts-check
class Zip {
    constructor() {
      this.encode = this.encode.bind(this);
      this.worker = new Worker(new URL('./zip_worker.js', import.meta.url), { type: 'module' });
    }
  
    /**
    * @param {String} fileName
    * @param {String} fileContent
    * @returns {Promise<String>}
    */
    async encode(fileName, fileContent) {
      /** @type {Worker} */
      return new Promise((resolve, reject) => {
        this.worker.postMessage({ fileContent, fileName});
        this.worker.onmessage = (event) => resolve(event.data);
        this.worker.onerror = (e) => reject(e);
      }).catch((e) => {
        return null;
      });
    }
  }
  /** @type {Zip} */
  const zip = new Zip();
  
  export default zip;