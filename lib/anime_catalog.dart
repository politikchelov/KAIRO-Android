import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _catalogBg = Color(0xFFFFF3F0);
const _catalogCard = Color(0xFFFFFFFF);
const _catalogPink = Color(0xFFEF7166);

class AnimeCatalogScreen extends StatefulWidget {
  const AnimeCatalogScreen({super.key, required this.onOpenAnime});
  final ValueChanged<String> onOpenAnime;

  @override
  State<AnimeCatalogScreen> createState() => _AnimeCatalogScreenState();
}

class _AnimeCatalogScreenState extends State<AnimeCatalogScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _searchMode = false;
  String? _error;
  int _request = 0;
  bool _grid = true;
  String _sort = 'По умолчанию';
  String _genre = 'Все';

  List<Map<String,dynamic>> get _visibleItems {
    var list = _items.where((x) => _genre == 'Все' || _genres(x).contains(_genre)).toList();
    if (_sort == 'По названию') list.sort((a,b)=>_title(a).compareTo(_title(b)));
    if (_sort == 'По рейтингу') list.sort((a,b)=>(double.tryParse(_string(b['score']??b['rating']))??0).compareTo(double.tryParse(_string(a['score']??a['rating']))??0));
    return list;
  }
  List<String> _genres(Map<String,dynamic> x) {
    final raw=x['genres']??x['genre']??x['tags'];
    if(raw is List) return raw.map(_string).where((s)=>s.isNotEmpty).toList();
    if(raw is String) return raw.split(RegExp(r'[,/]')).map((s)=>s.trim()).where((s)=>s.isNotEmpty).toList();
    return [];
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(_changed);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.removeListener(_changed);
    _search.dispose();
    super.dispose();
  }

  void _changed() {
    _debounce?.cancel();
    final q = _search.text.trim();
    if (q.isEmpty) {
      _load();
    } else if (q.length >= 2) {
      _debounce = Timer(const Duration(milliseconds: 450), () => _load(query: q));
    }
  }

  String _string(dynamic value) {
    if (value is String || value is num) return value.toString();
    if (value is Map) {
      for (final key in ['ru','russian','main','en','english','original','value','text']) {
        final v = value[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    return '';
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  String _title(Map<String, dynamic> x) {
    final n = _map(x['names']);
    final a = _map(x['anime'] ?? x['item'] ?? x['attributes'] ?? x['data']);
    for (final v in [
      x['title_ru'], x['russian_title'], x['title'], x['name'], n['ru'],
      n['russian'], x['title_en'], n['en'], x['original_title'],
      a['title_ru'], a['title'], a['name']
    ]) {
      final t = _string(v);
      if (t.isNotEmpty) return t;
    }
    return 'Без названия';
  }

  String _poster(Map<String, dynamic> x) {
    final p = _map(x['poster'] ?? x['image'] ?? x['cover']);
    final a = _map(x['anime'] ?? x['item'] ?? x['attributes'] ?? x['data']);
    final ap = _map(a['poster'] ?? a['image']);
    for (final v in [p['original'],p['large'],p['full'],p['src'],p['url'],
      x['poster'],x['image'],x['cover'],ap['original'],ap['large'],ap['url']]) {
      final t = _string(v);
      if (t.startsWith('http')) return t;
    }
    return '';
  }

  List<Map<String, dynamic>> _itemsFrom(dynamic data) {
    if (data is List) return data.whereType<Map>().map(_map).toList();
    if (data is! Map) return [];
    final d = _map(data['data']);
    final r = _map(data['results']);
    final p = _map(data['payload']);
    final lists = [data['data'],data['results'],data['items'],data['anime'],
      d['items'],d['results'],d['anime'],r['items'],p['items']];
    for (final list in lists) {
      if (list is List) return list.whereType<Map>().map(_map).toList();
    }
    return [];
  }

  Future<void> _load({String? query}) async {
    final id = ++_request;
    if (mounted) setState(() { _loading = true; _error = null; _searchMode = query != null; });
    try {
      final uri = Uri.parse('https://kaironet.vercel.app/api/anivibe').replace(
        queryParameters: {'action': query == null ? 'recent' : 'search',
          if (query != null) 'q': query, if (query != null) 'limit': '30'},
      );
      final response = await http.get(uri, headers: const {'Accept':'application/json'})
          .timeout(const Duration(seconds: 20));
      final data = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data is Map ? data['error']?.toString() : null;
        throw Exception(message ?? 'AniVibe временно недоступен');
      }
      final items = _itemsFrom(data).where((x) =>
        (x['id'] ?? x['anime_id'] ?? x['animeId']) != null &&
        _title(x) != 'Без названия').toList();
      if (!mounted || id != _request) return;
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (!mounted || id != _request) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _catalogPink,
      backgroundColor: _catalogCard,
      onRefresh: () => _load(query: _search.text.trim().length >= 2 ? _search.text.trim() : null),
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16,16,16,12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ТВОЯ АНИМЕ-ВСЕЛЕННАЯ',
                style: TextStyle(color: _catalogPink,fontSize:10,letterSpacing:2,fontWeight:FontWeight.w800)),
              const SizedBox(height:6),
              const Text('Найди свою историю',style:TextStyle(fontSize:25,fontWeight:FontWeight.w900)),
              const SizedBox(height:15),
              TextField(
                controller:_search,
                textInputAction:TextInputAction.search,
                onSubmitted:(v){if(v.trim().length>=2)_load(query:v.trim());},
                decoration:InputDecoration(
                  hintText:'Название аниме…',
                  prefixIcon:const Icon(Icons.search_rounded,color:_catalogPink),
                  suffixIcon:_search.text.isEmpty?null:IconButton(
                    onPressed:()=>_search.clear(),icon:const Icon(Icons.close_rounded)),
                  filled:true,fillColor:_catalogCard,
                  border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none),
                ),
              ),
              const SizedBox(height:15),
              Row(children:[
                Expanded(child:Text(_searchMode?'РЕЗУЛЬТАТЫ ПОИСКА':'ПОСЛЕДНИЕ ДОБАВЛЕНИЯ',
                  style:const TextStyle(fontSize:11,letterSpacing:1.4,color:Color(0xFF927A75),fontWeight:FontWeight.w800))),
                IconButton(tooltip:'Случайное аниме',onPressed:_items.isEmpty?null:(){
                  final x=_items[Random().nextInt(_items.length)];
                  widget.onOpenAnime((x['id']??x['anime_id']??x['animeId']).toString());
                },icon:const Icon(Icons.shuffle_rounded,color:_catalogPink)),
                IconButton(tooltip:_grid?'Список':'Сетка',onPressed:()=>setState(()=>_grid=!_grid),
                  icon:Icon(_grid?Icons.view_list_rounded:Icons.grid_view_rounded,color:_catalogPink)),
                PopupMenuButton<String>(tooltip:'Сортировка',onSelected:(v)=>setState(()=>_sort=v),
                  icon:const Icon(Icons.sort_rounded,color:_catalogPink),
                  itemBuilder:(_)=>const [PopupMenuItem(value:'По умолчанию',child:Text('По умолчанию')),PopupMenuItem(value:'По названию',child:Text('По названию')),PopupMenuItem(value:'По рейтингу',child:Text('По рейтингу'))]),
              ]),
              if(_items.isNotEmpty) ...[
                const SizedBox(height:6),
                SizedBox(height:36,child:ListView(scrollDirection:Axis.horizontal,children:[
                  for(final g in ['Все',..._items.expand(_genres).toSet().take(12)])
                    Padding(padding:const EdgeInsets.only(right:7),child:ChoiceChip(label:Text(g),selected:_genre==g,onSelected:(_)=>setState(()=>_genre=g),selectedColor:const Color(0xFFFFD5CE))),
                ])),
              ],
            ]),
          )),
          if (_loading)
            const SliverFillRemaining(hasScrollBody:false,child:Center(child:CircularProgressIndicator(color:_catalogPink)))
          else if (_error != null)
            SliverFillRemaining(hasScrollBody:false,child:Center(child:Padding(
              padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[
                const Icon(Icons.cloud_off_rounded,color:_catalogPink,size:44),
                const SizedBox(height:14),
                const Text('Каталог временно недоступен',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
                const SizedBox(height:8),
                Text(_error!,textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFF927A75))),
                const SizedBox(height:16),
                FilledButton(onPressed:()=>_load(query:_search.text.trim().length>=2?_search.text.trim():null),child:const Text('Повторить')),
              ]),
            )))
          else if (_visibleItems.isEmpty)
            const SliverFillRemaining(hasScrollBody:false,child:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
              Icon(Icons.search_off_rounded,color:_catalogPink,size:44),
              SizedBox(height:12),Text('Ничего не найдено',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
              SizedBox(height:6),Text('Попробуй другое название',style:TextStyle(color:Color(0xFF927A75))),
            ])))
          else
            SliverPadding(padding:const EdgeInsets.fromLTRB(14,0,14,28),sliver:SliverGrid(
              gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:2,mainAxisSpacing:14,crossAxisSpacing:12,childAspectRatio:.61),
              delegate:SliverChildBuilderDelegate((context,index){
                final x=_visibleItems[index];
                final id=(x['id']??x['anime_id']??x['animeId']).toString();
                final poster=_poster(x);
                final title=_title(x);
                final year=_string(x['year']??_map(x['aired'])['year']);
                final score=_string(x['score']??x['rating']);
                return Material(
                  color:_catalogCard,borderRadius:BorderRadius.circular(15),clipBehavior:Clip.antiAlias,
                  child:InkWell(onTap:()=>widget.onOpenAnime(id),child:Column(
                    crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Expanded(child:Stack(fit:StackFit.expand,children:[
                        if(poster.isNotEmpty) Image.network(poster,fit:BoxFit.cover,
                          errorBuilder:(_,__,___)=>const _PosterFallback())
                        else const _PosterFallback(),
                        const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(
                          begin:Alignment.topCenter,end:Alignment.bottomCenter,
                          colors:[Colors.transparent,Color(0x9906000D)]))),
                        if(score.isNotEmpty)Positioned(top:8,right:8,child:DecoratedBox(
                          decoration:BoxDecoration(color:const Color(0xCC100819),borderRadius:BorderRadius.circular(20)),
                          child:Padding(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),
                            child:Text('★ '+score,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w800))))),
                      ])),
                      Padding(padding:const EdgeInsets.fromLTRB(10,9,10,10),child:Column(
                        crossAxisAlignment:CrossAxisAlignment.start,children:[
                          Text(title,maxLines:2,overflow:TextOverflow.ellipsis,
                            style:const TextStyle(fontSize:13,fontWeight:FontWeight.w800,height:1.2)),
                          if(year.isNotEmpty)Padding(padding:const EdgeInsets.only(top:4),
                            child:Text(year,style:const TextStyle(fontSize:11,color:Color(0xFF927A75)))),
                        ])),
                    ])),
                );
              },childCount:_items.length),
            )),
        ],
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();
  @override
  Widget build(BuildContext context)=>const ColoredBox(
    color:Color(0xFFF5DAD5),child:Center(child:Icon(Icons.movie_creation_outlined,color:_catalogPink,size:34)));
}
