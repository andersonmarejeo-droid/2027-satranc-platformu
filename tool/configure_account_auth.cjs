// Uses the CLI's normal signed-in authorization. Never logs credentials/config.
const path=require('node:path');
const root=path.resolve(__dirname,'..');
const firebase=require(path.join(root,'.tools/firebase-cli/node_modules/firebase-tools'));
const {Client}=require(path.join(root,'.tools/firebase-cli/node_modules/firebase-tools/lib/apiv2'));
(async()=>{
  console.log('Checking signed-in Firebase access');
  await firebase.apps.list('ANDROID',{project:'satranc-platformu',nonInteractive:true});
  const client=new Client({urlPrefix:'https://identitytoolkit.googleapis.com',apiVersion:'v2'});
  const configPath='/projects/satranc-platformu/config';
  console.log('Checking email provider');
  const before=(await client.get(configPath)).body;
  const email=before.signIn?.email;
  if(!email?.enabled || email.passwordRequired!==true) {
    await client.patch(configPath,{signIn:{email:{enabled:true,passwordRequired:true}}},
      {queryParams:{updateMask:'signIn.email.enabled,signIn.email.passwordRequired'}});
  }
  const after=(await client.get(configPath)).body;
  console.log(JSON.stringify({emailEnabled:after.signIn?.email?.enabled===true,
    passwordRequired:after.signIn?.email?.passwordRequired===true,
    anonymousEnabled:after.signIn?.anonymous?.enabled===true}));
})().catch(e=>{console.error('Account provider configuration failed ('+(e.status ?? e.code ?? e.name)+')');process.exitCode=1;});
