module main;

pragma(lib, "ProxyGetterLibrary");

import std.stdio;
import std.string;

//private struct ProxyAndPortC {
//	
//	const char* proxy;
//	int port;
//
//};
//
//private struct ProxyAndPort {
//
//	string proxy;
//	int port;
//
//};
//
//private extern (C) ProxyAndPortC getHttpProxyAndPort(const char* proxyType, const char* portType);
//
//
///// Using the Cocoa API, get a given proxy server and corresponding port.
//private ProxyAndPort getHttpProxyAndPort(string proxyType, string portType) {
//
//	auto proxyAndPortC = getHttpProxyAndPort(proxyType.toStringz, portType.toStringz);
//	string proxy = fromStringz(proxyAndPortC.proxy).idup;
//
//	return ProxyAndPort(proxy, proxyAndPortC.port);
//
//}
//
//ProxyAndPort getHttpProxyAndPort(ProxyType proxyType) {
//
//	import std.conv;
//	import std.uni;
//
//	auto proxyName = proxyType.to!string.toUpper ~ "Proxy";
//	auto portName = proxyType.to!string.toUpper ~ "Port";
//
//	return getHttpProxyAndPort(proxyName, portName);
//
//}

enum ProxyType {
	
	http,
	https,
	ftp,
	socks,
	no
	
}

private extern (Objective-C)
	interface ClassObjC
{
	NSStringObjC alloc() @selector("alloc");
}

private extern (Objective-C)
	interface NSStringObjC
{
	NSStringObjC initWithUTF8String(in char* str) @selector("initWithUTF8String:");
	immutable(char)* UTF8String() @selector("UTF8String");
	void release() @selector("release");
}

private extern (Objective-C)
	interface NSDictionaryObjC
{
	NSStringObjC objectForKey(NSStringObjC) @selector("objectForKey:");
	void release() @selector("release");
}

private extern (C) ClassObjC objc_lookUpClass(in char* name);

private extern (C) NSDictionaryObjC getProxyTable();

/// Wrapper to NSString.
private struct NSString {

private:
	NSStringObjC nsStringObjC;
	@property NSStringObjC objectiveCObject() { return nsStringObjC; }

public:

	@property immutable(char)* toStringz() { return nsStringObjC.UTF8String; }
	@property string toString() { return fromStringz(toStringz).idup; }


	this(string input) {

		auto classLookup = objc_lookUpClass("NSString");
		this.nsStringObjC = classLookup.alloc().initWithUTF8String(input.toStringz);

	}

	~this() {

		this.nsStringObjC.release();

	}

}

/// Wrapper to NSDictionary.
private class NSDictionary {
	
private:
	NSDictionaryObjC nsDictionaryObjC;
	@property NSDictionaryObjC objectiveCObject() { return nsDictionaryObjC; }

public:

	string opIndex(string key) {

		auto nsKey = NSString(key);

		// NB: The following as an NSString that is "owned" by the dictionary,
		// so don't try to release it.
		auto valueObjC = nsDictionaryObjC.objectForKey(nsKey.objectiveCObject);

		// Now, simply extract the C string and convert to a D string.
		auto valueC = valueObjC.UTF8String;
		auto value = fromStringz(valueC).idup;

		return value;

	}

	this(NSDictionaryObjC nsDictionaryObjC) {
		
		this.nsDictionaryObjC = nsDictionaryObjC;

	}

	~this() {

		nsDictionaryObjC.release();

	}
	
}

void main(string[] args)
{
	import std.typecons;


//	ProxyAndPort proxyAndPort = getHttpProxyAndPort(ProxyType.https);
//
//	writefln("proxy: %s; port: %s", proxyAndPort.proxy, proxyAndPort.port);

	auto nsProxies = new NSDictionary(getProxyTable());
	auto proxyType = NSString("HTTPProxy");

	writeln(nsProxies["HTTPPort"]);

}

