library tool.tasks.update_example_html;

import 'dart:async';
import 'dart:io';
import 'package:bot/bot.dart';
import 'package:bot/hop.dart';
import 'package:html5lib/dom.dart';
import 'package:html5lib/parser.dart';
import 'package:html5lib/dom_parsing.dart';

import 'shared.dart';

const _startPath = r'example/bot_retained';
const _demoFinder = r'/**/*_demo.html';
final _exampleFile = _startPath + '/index.html';

Task getUpdateExampleHtmlTask() {
  return new Task.async((ctx) {
    return _getExampleFiles()
        .then((List<String> demos) {
          ctx.info(demos.join('\n'));

          return _transform(demos);
        })
        .then((bool updated) {
          final String msg = updated ? '$_exampleFile updated!' : 'No changes to $_exampleFile';
          ctx.info(msg);
          return true;
        });
  }, description: 'Updated the sample file at $_exampleFile');
}

Future<bool> _transform(List<String> samples) {
  return transformHtml(_exampleFile, (Document doc) {
    _tweakDocument(doc, samples);
    return new Future<Document>.immediate(doc);
  });
}

void _tweakDocument(Document doc, List<String> samples) {

  final sampleList = doc.queryAll('ul')
      .where((Element e) => e.id == 'demo-list')
      .single;

  sampleList.children.clear();

  for(final example in samples) {
    final anchor = new Element.tag('a')
      ..attributes['href'] = '$example/${example}_demo.html'
      ..attributes['target'] = 'demo'
      ..innerHtml = example;

    final li = new Element.tag('li')
      ..children.add(anchor);
    sampleList.children.add(li);
  }

}

Future<List<String>> _getExampleFiles() {
  final findStr = _startPath + _demoFinder;
  return Process.run('bash', ['-c', 'find $findStr'])
      .then((ProcessResult pr) {
        return Util.splitLines(pr.stdout.trim())
            .map((path) {
              assert(path.startsWith(_startPath));
              final lastSlash = path.lastIndexOf('/');
              final name = path.substring(_startPath.length+1, lastSlash);
              // this could be a lot prettier...but...eh
              final targetPath = "$_startPath/$name/${name}_demo.html";
              assert(path == targetPath);
              return name;
            })
            .toList();
      });
}
