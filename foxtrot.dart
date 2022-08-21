import 'dart:async';
import 'dart:io';
import 'package:toml/toml.dart';

class Page {
    String name;
    String srcFilePath;
    Future<String>? data;

    Page(this.name, this.srcFilePath) {}

    Future<bool> init() async {
        var pageFile = File("in/" + this.srcFilePath);
        this.data = pageFile.readAsString();

        return true;
    }
}

void main() async {
    // load site config
    var configFile = await TomlDocument.load("in/test.toml");
    var config = configFile.toMap();
    var template = await File("in/template.html").readAsString();
    
    var pages = [];
    for (final e in config.entries) {
        if (e.key == "pages") {
            // iterate over each page
            for (final p in e.value.entries) {
                var pageKey = p.key;
                var pageConfig = p.value;
                var page = (pageKey == "home" || pageKey == "index")
                         ? Page("Home", pageConfig["src"])
                         : Page(pageConfig["name"], pageConfig["src"]);
                pages.add(page);
            }
        }
    }

    if (pages.isEmpty) {
        print("Could not find page list!");
        return;
    }

    for (final p in pages) {
        print(p.name);
    }

    // read each page
    for (final p in pages) {
        p.init();
    }
    /*for (final p in pages) {
        print(await p.data);
    }*/

    // create navbar
    String navbar = "";
    for (final p in pages) {
        navbar += "<div class=\"col-xs-${12 ~/ pages.length}\">\n  <a href=\"/${p.srcFilePath}\">${p.name}</a>\n</div>\n";
        //navbar += "<div class=\"col-xs-1\">\n  <a href=\"/${p.srcFilePath}\">${p.name}</a>\n</div>\n";
    }

    //print(navbar);

    // substitute content in template
    String navbar_pattern = "{{{FOXTROT navbar}}}";
    String content_pattern = "{{{FOXTROT content}}}";
    var pages_out = {};
    for (final p in pages) {
        String pout;
        pout = template.replaceAllMapped(navbar_pattern, (Match _) => navbar);
        var data = await p.data;
        pout = pout.replaceAllMapped(content_pattern, (Match _) => data);
        pages_out[p.srcFilePath] = pout;
    }

    // write output
    var outDir = Directory("out");
    if (await outDir.exists()) {
        await outDir.delete(recursive: true);
    }
    await outDir.create();
    for (final p in pages_out.entries) {
        var outFile = File("out/" + p.key);
        await outFile.writeAsString(p.value);
    }

    // copy extra files
    var styleFile = File("in/styles.css");
    await styleFile.copy("out/styles.css");

    //print(pages);
}