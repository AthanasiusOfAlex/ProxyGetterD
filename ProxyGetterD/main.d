module main;

import std.conv;
import std.stdio;
import std.string;
import std.traits;
import std.range;

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


enum OwnerStatus {

	isOwner,
	isNotOwner

}

private extern (Objective-C)
	interface ClassObjC
{
	NSStringObjC allocNSString() @selector("alloc");
	NSNumberObjC allocNSNumber() @selector("alloc");
}

private extern (Objective-C)
	interface NSStringObjC
{
	NSStringObjC initWithUTF8String(in char* str) @selector("initWithUTF8String:");
	immutable(char)* UTF8String() @selector("UTF8String");
	void release() @selector("release");
}

private extern (Objective-C)
	interface NSNumberObjC
{
	NSNumberObjC initWithInt(in int number) @selector("initWithInt:");
	int intValue() @selector("intValue");
	void release() @selector("release");
}

private extern (Objective-C)
	interface NSDictionaryObjC
{
	NSStringObjC nsStringForKey(NSStringObjC key) @selector("objectForKey:");
	NSNumberObjC nsNumberForKey(NSStringObjC key) @selector("objectForKey:");
	NSArrayObjC allKeys() @selector("allKeys");
	void release() @selector("release");
}

private extern (Objective-C)
	interface NSArrayObjC
{
	NSStringObjC stringAtIndex(uint index) @selector("objectAtIndex:");
	uint count() @selector("count");
	void release() @selector("release");
}

private extern (C) ClassObjC objc_lookUpClass(in char* name);

extern (C) struct objc_class;
alias Class = objc_class*;
extern (C) struct objc_object {
	Class isa;
};
alias id = objc_object*;

/// Wrapper to NSString.
struct NSString {

private:
	NSStringObjC nsStringObjC;
	@property NSStringObjC objectiveCObject() { return nsStringObjC; }

	/// If you intend for the object to take care of memory
	/// management, set this property to `OwnerStatus.isOwner`.
	/// If the object is owned by another object, be sure to
	/// set this property to `OwnerStatus.isNotOwner`; otherwise, the	///program will crash.
	OwnerStatus ownerStatus = OwnerStatus.isOwner;

public:

	@property immutable(char)* toStringz() { return nsStringObjC.UTF8String; }
	@property string toString() { return fromStringz(toStringz).idup; }

	/// Since this initializer just accepts an
	/// Objective-C pointer, we provide a way to
	/// tell the object not to manage the memory.
	/// Memory is managed by default; set the second
	/// argument to `OwnerStatus.isNotOwner` to
	/// turn this off.
	private this(NSStringObjC objectiveCObject, OwnerStatus ownerStatus = OwnerStatus.isOwner) {

		this.ownerStatus = ownerStatus;
		nsStringObjC = objectiveCObject;

	}

	this(string input) {
	
		auto classLookup = objc_lookUpClass("NSString");
		this.nsStringObjC = classLookup.allocNSString().initWithUTF8String(input.toStringz);

	}

	~this() {

		if(ownerStatus == OwnerStatus.isOwner) { this.nsStringObjC.release(); }

	}

}

/// Wrapper to NSNumber.
struct NSNumber {
	
private:

	NSNumberObjC nsNumberObjC;
	@property NSNumberObjC objectiveCObject() { return nsNumberObjC; }
	
	/// If you intend for the object to take care of memory
	/// management, set this property to `OwnerStatus.isOwner` (the default).
	/// If the object is owned by another object, be sure to
	/// set this property to `OwnerStatus.isNotOwner`; otherwise, the	///program will crash.
	OwnerStatus ownerStatus = OwnerStatus.isOwner;

public:

	@property int toInt() { return nsNumberObjC.intValue; }
	@property uint toUInt() { return nsNumberObjC.intValue; }

	this(uint input) {
		
		auto classLookup = objc_lookUpClass("NSNumber");
		this.nsNumberObjC = classLookup.allocNSNumber().initWithInt(input);
		
	}

	/// Since this initializer just accepts an
	/// Objective-C pointer, we provide a way to
	/// tell the object not to manage the memory.
	/// Memory is managed by default; set the second
	/// argument to `OwnerStatus.isNotOwner` to
	/// turn this off.
	private this(NSNumberObjC objectiveCObject, OwnerStatus ownerStatus = OwnerStatus.isOwner) {

		this.ownerStatus = ownerStatus;
		this.nsNumberObjC = objectiveCObject;

	}
	
	~this() {
		
		if(ownerStatus == OwnerStatus.isOwner) { this.nsNumberObjC.release(); }
		
	}
	
}

/// Wrapper to NSDictionary.
struct NSDictionary {
	
private:
	NSDictionaryObjC nsDictionaryObjC;
	@property NSDictionaryObjC objectiveCObject() { return nsDictionaryObjC; }
	@property NSArray allKeys() { return new NSArray(nsDictionaryObjC.allKeys); }

	/// If you intend for the object to take care of memory
	/// management, set this property to `OwnerStatus.isOwner` (the default).
	/// If the object is owned by another object, be sure to
	/// set this property to `OwnerStatus.isNotOwner`; otherwise, the
	/// program will crash.
	OwnerStatus ownerStatus = OwnerStatus.isOwner;

public:
	
	T getValue(T)(string key)
		if(is(T==int) || is(T==string))
	{

		auto nsKey = NSString(key);

		// Now, simply extract the value and convert to a D type.
		static if(is(T==int)) {

			// NB: The following is an NSNumber that is "owned" by the dictionary,
			// so don't try to manage the memory.
			auto nsValue = NSNumber(nsDictionaryObjC.nsNumberForKey(nsKey.objectiveCObject), OwnerStatus.isNotOwner);
			auto value = nsValue.toInt;

		} else static if(is(T==string)) {

			// NB: The following is an NSString that is "owned" by the dictionary,
			// so don't try to manage the memory.
			auto nsValue = NSString(nsDictionaryObjC.nsStringForKey(nsKey.objectiveCObject), OwnerStatus.isNotOwner);
			auto value = nsValue.toString;

		} else {

			assert(false, "The type should be int or string.");

		}

		return value;

	}

	/// Since this initializer just accepts an
	/// Objective-C pointer, we provide a way to
	/// tell the object not to manage the memory.
	/// Memory is managed by default; set the second
	/// argument to `OwnerStatus.isNotOwner` to
	/// turn this off.
	private this(NSDictionaryObjC objectiveCObject, OwnerStatus ownerStatus = OwnerStatus.isOwner) {

		this.ownerStatus = ownerStatus;
		this.nsDictionaryObjC = objectiveCObject;

	}

	~this() {

		if(ownerStatus == OwnerStatus.isOwner) { nsDictionaryObjC.release(); }

	}
	
}

/// Simplified wrapper to NSArray.
class NSArray {

private:

	NSArrayObjC nsArrayObjC;
	@property NSArrayObjC objectiveCObject() { return nsArrayObjC; }
	uint currentIndex = 0;

	/// If you intend for the object to take care of memory
	/// management, set this property to `OwnerStatus.isOwner` (the default).
	/// If the object is owned by another object, be sure to
	/// set this property to `OwnerStatus.isNotOwner`; otherwise, the
	/// program will crash.
	OwnerStatus ownerStatus = OwnerStatus.isOwner;

public:

	// The following makes NSArray a forward range.
	@property bool empty() { return count - currentIndex <= 0; }
	@property string front() { return this[currentIndex]; }
	@property void popFront() { ++currentIndex; }

	string opIndex(int index) {

		NSString value = NSString(nsArrayObjC.stringAtIndex(currentIndex), OwnerStatus.isNotOwner);
		return value.toString;

	}

	@property int count() { return nsArrayObjC.count; }

	/// Since this initializer just accepts an
	/// Objective-C pointer, we provide a way to
	/// tell the object not to manage the memory.
	/// Memory is managed by default; set the second
	/// argument to `OwnerStatus.isNotOwner` to
	/// turn this off.
	private this(NSArrayObjC objectiveCObject, OwnerStatus ownerStatus = OwnerStatus.isOwner) {

		this.ownerStatus = ownerStatus;
		nsArrayObjC = objectiveCObject;

	}

	~this() {

		if(ownerStatus == OwnerStatus.isOwner) { nsArrayObjC.release(); }

	}

}

extern (C) struct __CFAllocator;
alias CFAllocatorRef = __CFAllocator*;

extern (C) struct __CFString;
alias CFStringRef =  __CFString*;

alias CFStringEncoding = uint;
enum CFStringEncoding kCFStringEncodingUTF8 = 0x08000100;

extern (C) CFStringRef CFStringCreateWithCString(CFAllocatorRef alloc, immutable(char) *cStr, CFStringEncoding encoding);

alias CFTypeRef = void*;
extern (C) void CFRelease(CFTypeRef cf);


extern (C) struct  __SCDynamicStore;
alias SCDynamicStoreRef = __SCDynamicStore*;
alias SCDynamicStoreCallBack = void*;
extern (C) struct SCDynamicStoreContext;

extern (C) struct __CFDictionary;
alias CFDictionaryRef = __CFDictionary*;

extern (C) SCDynamicStoreRef SCDynamicStoreCreate(
	CFAllocatorRef allocator,
	CFStringRef name,
	SCDynamicStoreCallBack callout,
	SCDynamicStoreContext * context
	);

extern (C) CFDictionaryRef SCDynamicStoreCopyProxies (SCDynamicStoreRef store);



// Wrapper for CFString and CFStringRef. It gets initialized with a string.
struct CFString {

private:
	CFStringRef cfStringRef;
	OwnerStatus ownerStatus = OwnerStatus.isOwner;

	/// Returns the original c pointer.
	/// WARNING! This is totally unsafe. Use the
	/// pointer ONLY during the lifetime of the
	/// struct!
	@property CFStringRef cPointer() { return cfStringRef; }

	/// If you don't intend for this struct to manage
	/// the memory (i.e, if you intend to be able to use
	/// the pointer once you have transferred it to the
	/// struct, and will release it afterwards youself),
	/// set ownerStatus to `OwnerStatus.isNotOwnser`.
	this(CFStringRef cPointer, OwnerStatus ownerStatus = OwnerStatus.isOwner) {

		this.ownerStatus = ownerStatus;
		this.cfStringRef = cPointer;

	}

public:

	this(string input) {

		cfStringRef = CFStringCreateWithCString(null, input.toStringz, kCFStringEncodingUTF8);

	}

	~this() {

		if(ownerStatus == OwnerStatus.isOwner) { CFRelease(cfStringRef); }

	}

}

NSDictionary getProxyList() {

	auto storeName = CFString("app");
	auto store = SCDynamicStoreCreate(null, storeName.cPointer, null, null);
	auto proxiesObjC = cast(NSDictionaryObjC)SCDynamicStoreCopyProxies(store);

	return NSDictionary(proxiesObjC);

}

void main(string[] args)
{

	import std.typecons;

	NSDictionary proxies = getProxyList();

	foreach (member; EnumMembers!ProxyType) {

		writefln(
			"Proxy type: %s; proxy server: %s; port: %s; enabled: %s",
			member,
			proxies.getValue!string(member.proxyKey),
			proxies.getValue!int(member.portKey),
			proxies.getValue!int(member.enableKey));

	}

}

