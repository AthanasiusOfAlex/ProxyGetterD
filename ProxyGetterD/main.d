module main;

import std.stdio;
import std.traits;
import ProxyGetter.ProxyGetter;

// TODO:
//   (1) Use Cocoa's enums to get the proxy settings:
//       https://developer.apple.com/reference/systemconfiguration/1517088-scdynamicstorecopyproxies
//   (2) Get the exceptions list (not essential for my project).
//

void main(string[] args)
{

	auto proxyTable = getProxyTable();

	foreach(key, value; proxyTable) {

		writefln("Proxy type: %s; address: %s; port: %s; enabled? %s",
			key,
			value.address,
			value.port,
			value.isEnabled);
			
	}

	writeln(getHttpProxy());
}

