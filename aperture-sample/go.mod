module github.com/golang/protobuf/aperture-sample

go 1.13

// aperture: use 1.3.x based fork for compatibility
replace github.com/golang/protobuf => github.com/aperturerobotics/go-protobuf-1.3.x v0.0.0-20200705233748-404297258551 // aperture-1.3.x

require (
	github.com/golang/protobuf v1.4.1
	google.golang.org/protobuf v1.25.0
)
