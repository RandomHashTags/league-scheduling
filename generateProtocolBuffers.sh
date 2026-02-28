protoc \
--proto_path=./Sources/ProtocolBuffers \
--proto_path=./.build/checkouts/swift-sports/Sources/ProtocolBuffers \
--proto_path=./.build/checkouts/swift-staticdatetime/Sources/ProtocolBuffers \
--swift_out=Visibility=Public:./Sources/league-scheduling/generated \
--swift_opt=ProtoPathModuleMappings=protobufModuleMappings.proto \
./Sources/ProtocolBuffers/*.proto