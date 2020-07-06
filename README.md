# Go support for Protocol Buffers - Google's data interchange format

Google's data interchange format.
Copyright 2010 The Go Authors.
https://github.com/golang/protobuf

This package and the code it generates requires at least Go 1.9.

This software implements Go bindings for protocol buffers.  For
information about protocol buffers themselves, see
	https://developers.google.com/protocol-buffers/

## Using protocol buffers with Go ##

The standard Makefile template to use is available in this repo. You can find it
under [aperture-sample](./aperture-sample). You need both the Makefile and the
hack/ dir.

```
SHELL := /bin/bash
export GO111MODULE=on
GOLIST=go list -f "{{ .Dir }}" -m

GOLANGCI_LINT=hack/bin/golangci-lint
PROTOC_GEN_GO=hack/bin/protoc-gen-go
PROTOWRAP=hack/bin/protowrap

all:

vendor:
	go mod vendor

$(PROTOC_GEN_GO):
	cd ./hack; \
	go build -v \
		-o ./bin/protoc-gen-go \
		github.com/golang/protobuf/protoc-gen-go

$(PROTOWRAP):
	cd ./hack; \
	go build -v \
		-o ./bin/protowrap \
		github.com/square/goprotowrap/cmd/protowrap

$(GOLANGCI_LINT):
	cd ./hack; \
	go build -v \
		-o ./bin/golangci-lint \
		github.com/golangci/golangci-lint/cmd/golangci-lint

genproto: $(PROTOWRAP) $(PROTOC_GEN_GO) vendor
	shopt -s globstar; \
	set -eo pipefail; \
	export GO111MODULE=on; \
	export PROJECT=$$(go list -m); \
	export PATH=$$(pwd)/hack/bin:$${PATH}; \
	mkdir -p $$(pwd)/vendor/$$(dirname $${PROJECT}); \
	rm $$(pwd)/vendor/$${PROJECT} || true; \
	ln -s $$(pwd) $$(pwd)/vendor/$${PROJECT} ; \
	$(PROTOWRAP) \
		-I $$(pwd)/vendor \
		--go_out=plugins=grpc:$$(pwd)/vendor \
		--proto_path $$(pwd)/vendor \
		--print_structure \
		--only_specified_files \
		$$(\
			git \
				ls-files "*.proto" |\
				xargs printf -- \
				"$$(pwd)/vendor/$${PROJECT}/%s ")

gengo: genproto

lint: $(GOLANGCI_LINT)
	$(GOLANGCI_LINT) run ./...

test:
	go test -v ./...
```

## gRPC Support ##

If a proto file specifies RPC services, protoc-gen-go can be instructed to
generate code compatible with gRPC (http://www.grpc.io/). To do this, pass
the `plugins` parameter to protoc-gen-go; the usual way is to insert it into
the --go_out argument to protoc:

	protoc --go_out=plugins=grpc:. *.proto

## Example Proto File

```proto
syntax = "proto3";
package chain;

import "github.com/aperturerobotics/hydra/block/object/object.proto";
import "github.com/aperturerobotics/hydra/cid/cid.proto";

// RootState is the chain state object in storage.
message RootState {
  // GenesisRef is the genesis reference we expect.
  cid.BlockRef genesis_ref = 1;
  // BucketId is the bucket id to use on default.
  string bucket_id = 2;
  // ChainId is the chain id.
  string chain_id = 3;

  // HeadBlockRef is the head block reference.
  // This is the latest VALID block available.
  // This block may become invalid at a later time.
  // May be empty if there is no HEAD.
  object.ObjectRef head_block_ref = 4;
}
```

Cross-repo lookups work fine, even with modules, using the makefile provided.

## Compatibility ##

The library and the generated code are expected to be stable over time.
However, we reserve the right to make breaking changes without notice for the
following reasons:

- Security. A security issue in the specification or implementation may come to
  light whose resolution requires breaking compatibility. We reserve the right
  to address such security issues.
- Unspecified behavior.  There are some aspects of the Protocol Buffers
  specification that are undefined.  Programs that depend on such unspecified
  behavior may break in future releases.
- Specification errors or changes. If it becomes necessary to address an
  inconsistency, incompleteness, or change in the Protocol Buffers
  specification, resolving the issue could affect the meaning or legality of
  existing programs.  We reserve the right to address such issues, including
  updating the implementations.
- Bugs.  If the library has a bug that violates the specification, a program
  that depends on the buggy behavior may break if the bug is fixed.  We reserve
  the right to fix such bugs.
- Adding methods or fields to generated structs.  These may conflict with field
  names that already exist in a schema, causing applications to break.  When the
  code generator encounters a field in the schema that would collide with a
  generated field or method name, the code generator will append an underscore
  to the generated field or method name.
- Adding, removing, or changing methods or fields in generated structs that
  start with `XXX`.  These parts of the generated code are exported out of
  necessity, but should not be considered part of the public API.
- Adding, removing, or changing unexported symbols in generated code.

Any breaking changes outside of these will be announced 6 months in advance to
protobuf@googlegroups.com.

You should, whenever possible, use generated code created by the `protoc-gen-go`
tool built at the same commit as the `proto` package.  The `proto` package
declares package-level constants in the form `ProtoPackageIsVersionX`.
Application code and generated code may depend on one of these constants to
ensure that compilation will fail if the available version of the proto library
is too old.  Whenever we make a change to the generated code that requires newer
library support, in the same commit we will increment the version number of the
generated code and declare a new package-level constant whose name incorporates
the latest version number.  Removing a compatibility constant is considered a
breaking change and would be subject to the announcement policy stated above.

The `protoc-gen-go/generator` package exposes a plugin interface,
which is used by the gRPC code generation. This interface is not
supported and is subject to incompatible changes without notice.

## Why fork it from the upstream?

The upstream moved to a google-backed repository with a breaking API change. The
entire Aperture stack including Kubernetes is currently using the 1.3.x version,
which works fine. If anything, the switch would be to code-generated marshal /
unmarshal types. The approach used to shoe-horn the new repository into the old,
disguised as a minor version bump (1.3.x -> 1.4.x) is also particularly
concerning.

This fork will maintain the 1.3.x line and pull patches from other 1.3.x maint
upstreams, until either a move to 1.4.x is possible or a better alternative
(like gogo protobuf or streaming encoding or flatbuffers) is used.

