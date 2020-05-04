# muna

Clean a series of links, resolving redirects and finding Wayback results if page is gone

![agaetr logo](https://raw.githubusercontent.com/uriel1998/muna/master/muna-open-graph.png "logo")

## Contents
 1. [About](#1-about)
 2. [License](#2-license)
 3. [Prerequisites](#3-prerequisites)
 4. [Installation](#4-installation)
 5. [Usage](#5-usage)
 6. [TODO](#6-todo)

***

## 1. About

There are two scripts here; `feeds-in` is specifically for [ArchiveBox](https://github.com/pirate/ArchiveBox), 
but `unredirector` is a bash script that can be sourced as a function in any other 
bash script.

I rather like [ArchiveBox](https://github.com/pirate/ArchiveBox) as a self-
hosted permanent archive of websites. However, just throwing a list of URLs 
(or worse, different types of RSS feeds) has... *mixed* results. So I took 
what I learned from [agaetr](https://github.com/uriel1998/agaetr) and created 
these scripts to clean up lists of links. 

If there's a redirect, whether from a shortener or, say, redirected to HTTPS, 
it will follow that and return (or save, if using `ArchiveBox`) the 
appropriate URL. If there is any other error (including if the page is gone or 
the server has disappeared), it will 

`muna` is an old norse word meaning call to mind, remember

## 2. License

This project is licensed under the Apache License. For the full license, see `LICENSE`.

## 3. Prerequisites

* bash
* find
* sed 
* sort
* cut

## 4. Installation


## 5. Usage

## 6. TODO


### Roadmap:

