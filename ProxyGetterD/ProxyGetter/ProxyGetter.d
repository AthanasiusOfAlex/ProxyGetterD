module ProxyGetter.ProxyGetter;

public import ProxyGetter.CocoaInterface;

import std.conv: to;
import std.string;

enum ProxyType {
	
	http,
	https,
	ftp,
	socks,
	
}

string proxyKey(ProxyType proxyType) {
	
	return proxyType.to!string.toUpper ~ "Proxy";

}

string portKey(ProxyType proxyType) {
	
	return proxyType.to!string.toUpper ~ "Port";
	
}

string enableKey(ProxyType proxyType) {
	
	return proxyType.to!string.toUpper ~ "Enable";
	
}

NSDictionary getProxyList() {

	return getProxySettingsDictionary();

}