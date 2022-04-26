# bzip2.swift

## What's This?

bzip2.swift the package to easy compress(decompress) bz2 Data in *Swift*
 
Deflate and decompress bz2 data was never been as easy.

```swift
// Compress data
let compressed = try Data(count: 10).bz2()
let compressed = try BZip2.compress(Data(count: 10))
// Decompress data
let decompressed = try Data(count: 10).fromBZ2()
let decompressed = try BZip2.decompress(Data(count: 10))
```

## TODO
- [ ] Handle files
- [ ] Tests
