module main;

import std.stdio;
import std.traits;
import ProxyGetter.ProxyGetter;

void main(string[] args)
{

	auto proxies = getProxyList();

//	foreach (member; EnumMembers!ProxyType) {
//
//		writefln(
//			"Proxy type: %s; proxy server: %s; port: %s; enabled: %s",
//			member,
//			proxies.getValue!string(member.proxyKey),
//			proxies.getValue!int(member.portKey),
//			proxies.getValue!int(member.enableKey));
//
//	}

}

