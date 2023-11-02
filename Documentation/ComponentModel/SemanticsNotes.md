# Component Model semantics notes

## Identifier namespace

Function and type names in an interface should be unique within the interface. Each interface has its own
namespace. A world has its own namespace for interface and function. An interface defined in a world with
the same name with another interface defined in a package should be distinguished.

```wit
package ns:pkg
interface iface {
  type my-type = u8
}
world w {
  interface ns-pkg-iface {
    type my-type = u32
  }
}
```
In Swift, we can't use kebab-case, `:`, and `/` in identifiers, so we need to transform the identifiers defined in WIT
to PascalCase by replacing `-`, `:`, and `/` and upcase the first letter following those symbols.
Therefore, our overlay code generator cannot accept the above WIT definition, while it conflicts `ns:pkg/iface`
and `ns-pkg-iface`. In the future, we can implement name escaping, but it requires careful transformation, so
we postponed its implementation for now.

## World

A World corresponds to a component, in Swift toolchain, a linked WebAssembly binary after wasm-ld.
A component contains only single World. A world can include other worlds, but items in the included Worlds
are flattened into the including World, it doesn't violate single-world rule.

## Import

A World can import `interface` and bare functions.
A function imported through `interface` defined in package-level has module name
`my-namespace:my-pkg/my-interface`. The namespace and package names are where the interface
is originally defined. Alias names in top-level use are not used in the import name.
A function imported through `interface` defined in world-level has module name `my-interface`.
A bare function defined directly in world like `import f: func()` has module name `$root`.

## Resource methods

A resource method can be defined within a `resource` definition. The Component Model proposal does not
explicitly specifies which component is responsible to provide the resource method definition, but usually a component
that exposes an interface that includes the resource type definition in WIT level is expected to provide the resource
methods. Consider the following example:
```
package example:http
interface handler {
  record header-entry {
    key: string,
    value: string,
  }
  resource blob {
    constructor(bytes: list<u8>)
    size: func() -> u32
  }
  record message {
    body: own<blob>,
    headers: list<header-entry>,
  }
  handle: func(request: message) -> message
}
world service {
  export handler
}
world middleware {
  import handler
  export handler
}
```

In this case, both `service` and `middleware` components are responsible to provide the following implementations:

- `example:http/handler#[constructor]blob`
- `example:http/handler#[dtor]blob`
- `example:http/handler#[method]blob.size`
- `example:http/handler#handle`

A type defined in `handler` interface can be shared between export and import interfaces unless it transitively
uses a `resource` type. In this case, `header-entry` type can be shared, but `message` and `blob` types can't.
This is because each resource type in import and export has its own constructor, destructor, and methods implementations
even though they both have the same raw representation. A `message` passing to or returned from an imported function
should call imported implementations and vice vasa.