{-# LANGUAGE JavaScriptFFI #-}

module Sound.MusicW.Worklets where

import GHCJS.Types
import GHCJS.Prim (toJSString)
import Control.Monad
import Control.Monad.IO.Class

import Sound.MusicW.AudioContext
import Sound.MusicW.Node
import Sound.MusicW.SynthDef

-- note: for any of these functions to work one must have
-- a secure browser context AND one must have
-- called (successfully) audioWorkletAddModule :: AudioContext -> String -> IO ()
-- with the String a URL that points to the location of worklets.js

equalWorklet :: AudioIO m => NodeRef -> NodeRef -> SynthDef m NodeRef
equalWorklet in1 in2 = audioWorklet "equal-processor" [in1,in2]

notEqualWorklet :: AudioIO m => NodeRef -> NodeRef -> SynthDef m NodeRef
notEqualWorklet in1 in2 = audioWorklet "notEqual-processor" [in1,in2]

greaterThanWorklet :: AudioIO m => NodeRef -> NodeRef -> SynthDef m NodeRef
greaterThanWorklet in1 in2 = audioWorklet "greaterThan-processor" [in1,in2]

greaterThanOrEqualWorklet :: AudioIO m => NodeRef -> NodeRef -> SynthDef m NodeRef
greaterThanOrEqualWorklet in1 in2 = audioWorklet "greaterThanOrEqual-processor" [in1,in2]

lessThanWorklet :: AudioIO m => NodeRef -> NodeRef -> SynthDef m NodeRef
lessThanWorklet in1 in2 = audioWorklet "lessThan-processor" [in1,in2]

lessThanOrEqualWorklet :: AudioIO m => NodeRef -> NodeRef -> SynthDef m NodeRef
lessThanOrEqualWorklet in1 in2 = audioWorklet "lessThanOrEqual-processor" [in1,in2]
 

audioWorklet :: AudioIO m => String -> [NodeRef] -> SynthDef m NodeRef
audioWorklet workletName inputs = do
  y <- addNodeBuilder $ createAudioWorkletNode (length inputs) 1 workletName
  zipWithM (\x n -> connect' x 0 y n) inputs [0..]
  return y

createAudioWorkletNode :: AudioIO m => Int -> Int -> String -> m Node
createAudioWorkletNode inChnls outChnls workletName = do
  ctx <- audioContext
  node <- liftIO $ js_createAudioWorkletNode ctx (toJSString workletName) inChnls outChnls
  setNodeField node "isSource" (outChnls > 0)
  setNodeField node "isSink" (inChnls > 0)
  setNodeField node "startable" False

foreign import javascript safe
  "new AudioWorkletNode($1, $2, { numberOfInputs: $3, numberOfOutputs: $4 } )"
  js_createAudioWorkletNode :: AudioContext -> JSVal -> Int -> Int -> IO Node

addWorklets :: AudioContext -> IO ()
addWorklets ac = do
  blob <- js_workletsBlob (toJSString workletsJS)
  url <- js_workletsURL blob
  js_audioWorkletAddModule ac url

foreign import javascript safe
  "new Blob([$1], { type: 'application/javascript' })"
  js_workletsBlob :: JSVal -> IO JSVal

foreign import javascript safe
  "URL.createObjectURL($1)"
  js_workletsURL :: JSVal -> IO JSVal

foreign import javascript safe
  "$1.audioWorklet.addModule($2);"
  js_audioWorkletAddModule :: AudioContext -> JSVal -> IO ()

workletsJS :: String  
workletsJS = "\
\ class EqualProcessor extends AudioWorkletProcessor {\
\  static get parameterDescriptors() {\
\    return [];\
\  }\
\  constructor() {\
\    super();\
\  }\
\  process(inputs,outputs,parameters) {\
\    const input1 = inputs[0];\
\    const input2 = inputs[1];\
\    const output = outputs[0];\
\    for(let i = 0; i < input1[0].length; i++) {\
\      if(input1[0][i] == input2[0][i]) output[0][i] = 1; else output[0][i] = 0;\
\    }\
\    return true;\
\  }\
\ }\
\ registerProcessor('equal-processor',EqualProcessor);\
\ \
\ class NotEqualProcessor extends AudioWorkletProcessor {\
\  static get parameterDescriptors() {\
\    return [];\
\  }\
\  constructor() {\
\    super();\
\  }\
\  process(inputs,outputs,parameters) {\
\    const input1 = inputs[0];\
\    const input2 = inputs[1];\
\    const output = outputs[0];\
\    for(let i = 0; i < input1[0].length; i++) {\
\      if(input1[0][i] != input2[0][i]) output[0][i] = 1; else output[0][i] = 0;\
\    }\
\    return true;\
\  }\
\ }\
\ registerProcessor('notEqual-processor',NotEqualProcessor);\
\ \
\ class GreaterThanProcessor extends AudioWorkletProcessor {\
\  static get parameterDescriptors() {\
\    return [];\
\  }\
\  constructor() {\
\    super();\
\  }\
\  process(inputs,outputs,parameters) {\
\    const input1 = inputs[0];\
\    const input2 = inputs[1];\
\    const output = outputs[0];\
\    for(let i = 0; i < input1[0].length; i++) {\
\      if(input1[0][i] > input2[0][i]) output[0][i] = 1; else output[0][i] = 0;\
\    }\
\    return true;\
\  }\
\ }\
\ registerProcessor('greaterThan-processor',GreaterThanProcessor);\
\ \
\ class GreaterThanOrEqualProcessor extends AudioWorkletProcessor {\
\  static get parameterDescriptors() {\
\    return [];\
\  }\
\  constructor() {\
\    super();\
\  }\
\  process(inputs,outputs,parameters) {\
\    const input1 = inputs[0];\
\    const input2 = inputs[1];\
\    const output = outputs[0];\
\    for(let i = 0; i < input1[0].length; i++) {\
\      if(input1[0][i] >= input2[0][i]) output[0][i] = 1; else output[0][i] = 0;\
\    }\
\    return true;\
\  }\
\ }\
\ registerProcessor('greaterThanOrEqual-processor',GreaterThanOrEqualProcessor);\
\ \
\ class LessThanProcessor extends AudioWorkletProcessor {\
\  static get parameterDescriptors() {\
\    return [];\
\  }\
\  constructor() {\
\    super();\
\  }\
\  process(inputs,outputs,parameters) {\
\    const input1 = inputs[0];\
\    const input2 = inputs[1];\
\    const output = outputs[0];\
\    for(let i = 0; i < input1[0].length; i++) {\
\      if(input1[0][i] < input2[0][i]) output[0][i] = 1; else output[0][i] = 0;\
\    }\
\    return true;\
\  }\
\ }\
\ registerProcessor('lessThan-processor',LessThanProcessor);\
\ \
\ class LessThanOrEqualProcessor extends AudioWorkletProcessor {\
\  static get parameterDescriptors() {\
\    return [];\
\  }\
\  constructor() {\
\    super();\
\  }\
\  process(inputs,outputs,parameters) {\
\    const input1 = inputs[0];\
\    const input2 = inputs[1];\
\    const output = outputs[0];\
\    for(let i = 0; i < input1[0].length; i++) {\
\      if(input1[0][i] <= input2[0][i]) output[0][i] = 1; else output[0][i] = 0;\
\    }\
\    return true;\
\  }\
\ }\
\ registerProcessor('lessThanOrEqual-processor',LessThanOrEqualProcessor);"

