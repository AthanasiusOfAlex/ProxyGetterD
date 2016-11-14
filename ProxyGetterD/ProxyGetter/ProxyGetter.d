module ProxyGetter.ProxyGetter;

public import ProxyGetter.CocoaInterface;

import std.string;
import std.traits;
import std.typecons;

struct ProxyEntry {

	string address;
	int port;
	bool isEnabled;
}

ProxyEntry[ProxyType] getProxyTable() {

	ProxyEntry[ProxyType] result;
	NSDictionary nsDictionary = getProxySettingsDictionary();

	foreach (proxyType; EnumMembers!ProxyType) {

		ProxyDictionaryKeys keys = getKeys(proxyType);

		string address = nsDictionary.getValue!string(keys.proxy);
		int port = nsDictionary.getValue!int(keys.port);
		int enable = nsDictionary.getValue!int(keys.enable);

		bool isEnabled;

		if (enable==0) {

			isEnabled = false;

		} else {

			isEnabled = true;
			
		}

		result[proxyType] = ProxyEntry(address, port, isEnabled);

	}

	return result;

}

Nullable!string getHttpProxy() {

	auto proxyEntry = getProxyTable()[ProxyType.http];
	Nullable!string result;

	if (proxyEntry.isEnabled) {
		
		result = format("%s:%s", proxyEntry.address, proxyEntry.port);

	} else {
		
		result.nullify();

	}

	return result;

}