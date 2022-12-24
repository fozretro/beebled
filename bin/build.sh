# Compile ./dist/beebled.ssd
beebasm -v -i ./src/beebled.asm -do ./dist/beebled.ssd -title BeebLED -boot BeebLED
# Expand it back out into the Beebs development workspace the BEEBLED file for local running and to update .inf file for BEEBLED
rm -rf ./dev/beebleddist
perl ./bin/mmbutils/beeb getfile ./dist/beebled.ssd ./dev/beebleddist
cp ./dev/beebleddist/BeebLED* ./dev/beebled