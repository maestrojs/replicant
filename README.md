# Replicant

Replicant provides a javascript object proxy so that you can intercept gets/sets to properties. It also provides a means to access members through a fully qualified namespace.

Replicant is currently a proof of concept. Do not use it for anything other than experimentation.

## Replicant Hates Lame Browsers

If it's not javascript 1.8.1 or better, Replicant can't help you. This may change but isn't a priority at this moment in time. If Replicant is worth your effort, patches will be accepted to improve its interoperability.

## Replicant Is Intentionally Sparse

I highly encourage the use of a local message bus in order to publish changes to the proxied object vs. attempting to inject a lot of complex operations into the get and set callbacks.

## To Do

* Add wrapper
* Abstract dynamic member creation
* Write tests