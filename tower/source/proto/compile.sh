#!/bin/bash
echo "compile all proto file started" 

#编译结果的存放目录
destination="../../protocol/"

for f in *.proto; do
	#statements
	echo "compile "$f
	protoc $f -o $destination${f%%.*}.pb
done
echo "compile complete"