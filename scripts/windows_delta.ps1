# Shared binary patch codec. Fixed 16 KiB blocks, compressed literals, exact SHA-256 bases.
if (-not ('MortalDelta' -as [type])) { Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Collections.Generic;
public static class MortalDelta {
 const int Block = 16384;
 static string Hash(byte[] bytes) { using(var h = SHA256.Create()) return BitConverter.ToString(h.ComputeHash(bytes)).Replace("-", "").ToLowerInvariant(); }
 static string Part(byte[] bytes, int start, int count) { using(var h = SHA256.Create()) return Convert.ToBase64String(h.ComputeHash(bytes,start,count)); }
 public static void Create(string basis, string target, string patch) {
  byte[] a=File.ReadAllBytes(basis), b=File.ReadAllBytes(target);
  var blocks=new Dictionary<string,int>();
  for(int i=0;i<a.Length;i+=Block) blocks[Part(a,i,Math.Min(Block,a.Length-i))]=i;
  using(var file=File.Create(patch)) using(var zip=new GZipStream(file,CompressionMode.Compress)) using(var w=new BinaryWriter(zip)) {
   w.Write("PMDELTA1"); w.Write(Hash(a)); w.Write(Hash(b)); w.Write(b.Length);
   for(int i=0;i<b.Length;i+=Block) {
    int count=Math.Min(Block,b.Length-i), offset;
    bool copy=blocks.TryGetValue(Part(b,i,count),out offset);
    w.Write(copy); w.Write(count);
    if(copy) w.Write(offset); else w.Write(b,i,count);
   }
  }
 }
 public static void Apply(string basis, string patch, string target) {
  byte[] a=File.ReadAllBytes(basis); string expected;
  using(var file=File.OpenRead(patch)) using(var zip=new GZipStream(file,CompressionMode.Decompress)) using(var r=new BinaryReader(zip)) {
   if(r.ReadString()!="PMDELTA1" || r.ReadString()!=Hash(a)) throw new InvalidDataException("Patch base mismatch");
   expected=r.ReadString(); int length=r.ReadInt32();
   if(length<2 || length>1073741824) throw new InvalidDataException("Patch size invalid");
   using(var output=File.Create(target)) {
    while(output.Length<length) {
     bool copy=r.ReadBoolean(); int count=r.ReadInt32();
     if(count<1 || count>Block || count>length-output.Length) throw new InvalidDataException("Invalid block");
     if(copy) { int offset=r.ReadInt32(); if(offset<0 || offset>a.Length-count) throw new InvalidDataException("Invalid offset"); output.Write(a,offset,count); }
     else { byte[] data=r.ReadBytes(count); if(data.Length!=count) throw new EndOfStreamException(); output.Write(data,0,count); }
    }
    if(r.BaseStream.ReadByte()!=-1) throw new InvalidDataException("Trailing patch data");
   }
  }
  if(Hash(File.ReadAllBytes(target))!=expected) throw new InvalidDataException("Reconstructed checksum mismatch");
 }
}
'@
}
