#  GameRecord Format

The game records store the essential information for the full game to be
recreated, and also partially transformed to make it closer to the samples and
labels used to train the value/prior ML model.

The records are stored in the protobuf format.
[Swift Protobuf](https://github.com/apple/swift-protobuf) is a dependency.

To regerenerate the Swift and Python classes:

```
protoc --swift_opt=Visibility=Public --swift_out=. DrillGameRecord.proto 
protoc --python_out=. DrillGameRecord.proto
```


