
  export function device_interface(device) {
    const interfaces = device.configurations[0].interfaces;
    for (let i = 0; i < interfaces.length; ++i) {
        const ifaceAlt = interfaces[i].alternates.find((a) => a.interfaceClass === 255);
        if (!ifaceAlt) { continue; }
        return { interface_number: interfaces[i].interfaceNumber, endpoint_number: ifaceAlt.endpoints[0].endpointNumber }
    }
    return null;
  }
