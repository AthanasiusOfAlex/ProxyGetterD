module main;

pragma(lib, "ProxyGetterLibrary");

import std.stdio;
import std.string;
import std.traits;

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
	NSStringObjC allocNSString() @selector("alloc");
	NSUIntegerObjC allocNSUInteger() @selector("alloc");
}

private extern (Objective-C)
	interface NSStringObjC
{
	NSStringObjC initWithUTF8String(in char* str) @selector("initWithUTF8String:");
	immutable(char)* UTF8String() @selector("UTF8String");
	void release() @selector("release");
}

private extern (Objective-C)
	interface NSUIntegerObjC
{
	NSUIntegerObjC initWithInt(in int number) @selector("initWithInt:");
	int intValue() @selector("intValue");
	void release() @selector("release");
}

private extern (Objective-C)
	interface NSDictionaryObjC
{
	NSStringObjC nsStringForKey(NSStringObjC key) @selector("objectForKey:");
	NSUIntegerObjC nsNumberForKey(NSStringObjC key) @selector("objectForKey:");
	void release() @selector("release");
}

private extern (Objective-C)
	interface NSArrayObjC
{
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
		this.nsStringObjC = classLookup.allocNSString().initWithUTF8String(input.toStringz);

	}

	~this() {

		this.nsStringObjC.release();

	}

}

/// Wrapper to NSUInteger.
private struct NSUInteger {
	
private:

	NSUIntegerObjC nsNumberObjC;
	@property NSUIntegerObjC objectiveCObject() { return nsNumberObjC; }
	
public:

	@property int toInt() { return nsNumberObjC.intValue; }
	@property uint toUInt() { return nsNumberObjC.intValue; }

	this(uint input) {
		
		auto classLookup = objc_lookUpClass("NSUInteger");
		this.nsNumberObjC = classLookup.allocNSUInteger().initWithInt(input);
		
	}
	
	~this() {
		
		this.nsNumberObjC.release();
		
	}
	
}

/// Wrapper to NSDictionary.
private class NSDictionary {
	
private:
	NSDictionaryObjC nsDictionaryObjC;
	@property NSDictionaryObjC objectiveCObject() { return nsDictionaryObjC; }

public:

	T getValue(T)(string key)
		if(is(T==int) || is(T==string))
	{

		auto nsKey = NSString(key);

		// Now, simply extract the value and convert to a D type.
		static if(is(T==int)) {

			// NB: The following as an NSUInteger that is "owned" by the dictionary,
			// so don't try to release it.
			auto valueObjC = nsDictionaryObjC.nsNumberForKey(nsKey.objectiveCObject);
			auto value = valueObjC.intValue;

		} else static if(is(T==string)) {

			// NB: The following as an NSString that is "owned" by the dictionary,
			// so don't try to release it.
			auto valueObjC = nsDictionaryObjC.nsStringForKey(nsKey.objectiveCObject);auto valueC = valueObjC.UTF8String;
			auto value = fromStringz(valueC).idup;

		} else {

			assert(false, "The type should be int or string.");

		}

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

	auto nsProxies = new NSDictionary(getProxyTable());

	writeln(nsProxies.getValue!string("HTTPProxy"), nsProxies.getValue!int("HTTPPort"), nsProxies.getValue!int("HTTP"));

}

