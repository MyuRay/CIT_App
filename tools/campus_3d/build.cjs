const fs=require('node:fs'),path=require('node:path');
const deps=process.env.CAMPUS_3D_NODE_MODULES||path.join(__dirname,'node_modules');
const esbuild=require(path.join(deps,'esbuild'));
const destination=path.resolve(__dirname,'../../assets/models/campus');
esbuild.buildSync({entryPoints:[path.join(__dirname,'entry.mjs')],bundle:true,format:'iife',target:'es2020',minify:true,legalComments:'external',nodePaths:[deps],outfile:path.join(destination,'campus_engine.js')});
fs.copyFileSync(path.join(__dirname,'viewer.html'),path.join(destination,'viewer.html'));
console.log('Built offline campus engine and preserved third-party license notices.');
