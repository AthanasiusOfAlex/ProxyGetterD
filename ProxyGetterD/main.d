module main;

import std.stdio;
import std.traits;
import ProxyGetter.ProxyGetter;

// TODO:
//   (1) see if NSDictionary can be implemented as an array of NSObject,
//       and then use introspection to get the correct datatype
//   (2) Use Cocoa's enums to get the proxy settings:
//       https://developer.apple.com/reference/systemconfiguration/1517088-scdynamicstorecopyproxies

void main(string[] args)
{

	auto proxies = getProxyList();

	foreach (member; EnumMembers!ProxyType) {

		writefln(
			"Proxy type: %s; proxy server: %s; port: %s; enabled: %s",
			member,
			proxies.getValue!string(member.proxyKey),
			proxies.getValue!int(member.portKey),
			proxies.getValue!int(member.enableKey));

	}

}

