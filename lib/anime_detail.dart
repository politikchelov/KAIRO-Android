import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'favorites_store.dart';
import 'library_store.dart';

const _detailBg = Color(0xFFFFF3F0);
const _detailPanel = Color(0xFFFFFFFF);
const _detailPink = Color(0xFFEF7166);

class AnimeDetailScreen extends StatefulWidget {
  const AnimeDetailScreen({super.key, required this.animeId});
  final String animeId;
  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  Map<String, dynamic>? _anime;
  List<dynamic> _episodes = [];
  Set<String> _watched = {};
  bool _loading = true, _isFavorite = false, _favoriteBusy = false, _expanded = false;
  String? _error;
  int? _selectedEpisode;
  int _rating = 0;
  String _note = '';

  Map<String, dynamic> _map(dynamic v) => v is Map ? Map<String,dynamic>.from(v) : {};
  dynamic _unwrap(dynamic v) => v is Map ? (v['data'] ?? v['anime'] ?? v) : v;
  List<dynamic> _episodeList(dynamic v) {
    if (v is List) return v;
    if (v is Map) {
      final d = _map(v['data']);
      for (final x in [v['episodes'],d['episodes'],v['data'],v['items'],v['results'],d['items'],d['results']]) {
        if (x is List) return x;
      }
    }
    return [];
  }
  String _text(dynamic v) {
    if (v is String || v is num) return v.toString();
    if (v is Map) { for (final k in ['ru','russian','main','en','original','value','text']) { final x=v[k]; if(x is String && x.trim().isNotEmpty)return x.trim(); } }
    return '';
  }
  String _title(Map<String,dynamic> x) {
    final n=_map(x['names']);
    for(final v in [x['title_ru'],x['russian_title'],x['title'],x['name'],n['ru'],n['russian'],x['title_en'],n['en'],x['original_title']]) { final s=_text(v); if(s.isNotEmpty)return s; }
    return 'Аниме';
  }
  String _poster(Map<String,dynamic> x) {
    final p=_map(x['poster']), i=_map(x['image']), c=_map(x['cover']);
    for(final v in [p['original'],p['large'],p['url'],p['src'],i['original'],i['large'],i['url'],c['original'],c['large'],x['poster_url'],x['poster'],x['image'],x['cover']]) {
      final s=_text(v); if(s.startsWith('http'))return s;
    }
    return '';
  }
  int _episodeNumber(dynamic e,int index) {
    final row=_map(e);
    for(final k in ['number','episode','ordinal','episode_number']) { final n=int.tryParse(_text(row[k])); if(n!=null&&n>0)return n; }
    return index+1;
  }

  @override
  void initState() { super.initState(); _load(); _loadLocal(); }
  Future<void> _loadLocal() async {
    final values=await Future.wait([FavoritesStore.contains(widget.animeId),KairoLibrary.watched(widget.animeId),KairoLibrary.rating(widget.animeId),KairoLibrary.note(widget.animeId)]);
    if(!mounted)return;
    setState(() { _isFavorite=values[0] as bool; _watched=values[1] as Set<String>; _rating=values[2] as int; _note=values[3] as String; });
  }
  Future<void> _load() async {
    setState(() { _loading=true; _error=null; });
    try {
      final base=Uri.parse('https://kaironet.vercel.app/api/anivibe');
      final responses=await Future.wait([
        http.get(base.replace(queryParameters:{'action':'anime','id':widget.animeId}),headers:const {'Accept':'application/json'}).timeout(const Duration(seconds:20)),
        http.get(base.replace(queryParameters:{'action':'episodes','id':widget.animeId}),headers:const {'Accept':'application/json'}).timeout(const Duration(seconds:20)),
      ]);
      for(final r in responses) { if(r.statusCode<200||r.statusCode>=300)throw Exception('AniVibe: HTTP ${r.statusCode}'); }
      final anime=_map(_unwrap(jsonDecode(responses[0].body)));
      final episodes=_episodeList(jsonDecode(responses[1].body));
      await KairoLibrary.viewed(id:widget.animeId,title:_title(anime),poster:_poster(anime));
      if(!mounted)return;
      setState(() { _anime=anime; _episodes=episodes; _loading=false; });
    } catch(e) { if(mounted)setState((){_error=e.toString().replaceFirst('Exception: ','');_loading=false;}); }
  }
  Future<void> _toggleFavorite() async {
    if(_favoriteBusy||_anime==null)return;
    setState(()=>_favoriteBusy=true);
    await FavoritesStore.toggle(FavoriteAnime(id:widget.animeId,title:_title(_anime!),poster:_poster(_anime!)));
    if(mounted)setState(()=>_favoriteBusy=false);
    if(mounted)setState(()=>_isFavorite=!_isFavorite);
  }
  Future<void> _toggleWatched(int index) async {
    final key=_episodeNumber(_episodes[index],index).toString();
    await KairoLibrary.toggleWatched(widget.animeId,key);
    if(!mounted)return;
    setState(() { if(!_watched.add(key))_watched.remove(key); });
  }
  Future<void> _editNote() async {
    final c=TextEditingController(text:_note);
    final value=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Мои заметки'),content:TextField(controller:c,maxLines:5,decoration:const InputDecoration(hintText:'Запиши мысли об этом аниме…')),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Отмена')),FilledButton(onPressed:()=>Navigator.pop(ctx,c.text),child:const Text('Сохранить'))]));
    if(value==null)return;
    await KairoLibrary.saveNote(widget.animeId,value);
    if(mounted)setState(()=>_note=value);
  }
  Future<void> _rate(int value) async { await KairoLibrary.setRating(widget.animeId,value); if(mounted)setState(()=>_rating=value); }
  Future<void> _copyTitle() async {
    await Clipboard.setData(ClipboardData(text:'${_title(_anime??{})} — KAIRO'));
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Название скопировано')));
  }

  @override
  Widget build(BuildContext context) {
    final a=_anime??{};
    final title=_title(a),poster=_poster(a);
    final description=_text(a['description']??a['synopsis']??a['about']??a['description_ru']);
    final shownDescription=_expanded||description.length<260?description:'${description.substring(0,260)}…';
    final year=_text(a['year']),score=_text(a['score']??a['rating']);
    return Scaffold(
      backgroundColor:_detailBg,
      appBar:AppBar(backgroundColor:_detailBg,title:const Text('KAIRO / ANIME'),actions:[
        IconButton(onPressed:_copyTitle,tooltip:'Скопировать название',icon:const Icon(Icons.copy_rounded)),
        IconButton(onPressed:_loading||_anime==null||_favoriteBusy?null:_toggleFavorite,tooltip:'Избранное',icon:Icon(_isFavorite?Icons.favorite:Icons.favorite_border,color:_detailPink)),
      ]),
      body:_loading?const Center(child:CircularProgressIndicator(color:_detailPink)):
      _error!=null?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(_error!,textAlign:TextAlign.center),TextButton(onPressed:_load,child:const Text('Повторить'))])):
      RefreshIndicator(color:_detailPink,onRefresh:_load,child:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,32),children:[
        ClipRRect(borderRadius:BorderRadius.circular(22),child:SizedBox(height:250,child:Stack(fit:StackFit.expand,children:[
          poster.isEmpty?const ColoredBox(color:_detailPanel,child:Icon(Icons.movie,size:55,color:_detailPink)):Image.network(poster,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const ColoredBox(color:_detailPanel,child:Icon(Icons.movie,size:55,color:_detailPink))),
          const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Color(0xDD000000)]))),
          Positioned(left:18,right:18,bottom:18,child:Text(title,style:const TextStyle(color:Colors.white,fontSize:25,fontWeight:FontWeight.w900))),
        ]))),
        const SizedBox(height:14),
        Wrap(spacing:8,runSpacing:8,children:[
          if(year.isNotEmpty)_chip(year),if(score.isNotEmpty)_chip('★ $score'),_chip('${_episodes.length} серий'),_chip('AniVibe'),_chip('${_watched.length}/${_episodes.length} просмотрено'),
        ]),
        if(description.isNotEmpty)...[
          const SizedBox(height:20),const Text('ОБ ЭТОЙ ИСТОРИИ',style:TextStyle(color:_detailPink,fontSize:10,letterSpacing:1.8,fontWeight:FontWeight.w900)),
          const SizedBox(height:8),Text(shownDescription,style:const TextStyle(color:Color(0xFF765E59),height:1.55)),
          if(description.length>260)Align(alignment:Alignment.centerLeft,child:TextButton(onPressed:()=>setState(()=>_expanded=!_expanded),child:Text(_expanded?'Свернуть':'Читать полностью'))),
        ],
        const SizedBox(height:18),
        Row(children:[const Expanded(child:Text('МОЯ ОЦЕНКА',style:TextStyle(fontWeight:FontWeight.w900))),Text(_rating==0?'Не оценено':'$_rating из 5',style:const TextStyle(color:Color(0xFF927A75)))]),
        Row(children:List.generate(5,(i)=>IconButton(onPressed:()=>_rate(i+1),icon:Icon(i<_rating?Icons.star:Icons.star_border,color:_detailPink)))),
        OutlinedButton.icon(onPressed:_editNote,icon:const Icon(Icons.edit_note_rounded),label:Text(_note.isEmpty?'Добавить личную заметку':'Изменить заметку')),
        if(_note.isNotEmpty)Container(margin:const EdgeInsets.only(top:8),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:_detailPanel,borderRadius:BorderRadius.circular(13)),child:Text(_note)),
        const SizedBox(height:22),
        Row(children:[const Expanded(child:Text('ЭПИЗОДЫ',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900))),Text('${_episodes.length} доступно',style:const TextStyle(color:Color(0xFF927A75),fontSize:12))]),
        const SizedBox(height:12),
        if(_episodes.isEmpty)const Text('Список серий пока недоступен.',style:TextStyle(color:Color(0xFF927A75)))
        else Wrap(spacing:9,runSpacing:9,children:List.generate(_episodes.length,(index){
          final n=_episodeNumber(_episodes[index],index),key=n.toString(),selected=_selectedEpisode==index,done=_watched.contains(key);
          return InkWell(onTap:()=>setState(()=>_selectedEpisode=index),onLongPress:()=>_toggleWatched(index),borderRadius:BorderRadius.circular(12),
            child:Container(width:58,height:55,decoration:BoxDecoration(color:done?const Color(0xFFFFD5CE):_detailPanel,borderRadius:BorderRadius.circular(12),border:Border.all(color:selected?_detailPink:const Color(0xFFF0D8D3),width:selected?2:1)),
              child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(n.toString().padLeft(2,'0'),style:TextStyle(fontWeight:FontWeight.w900,color:done?_detailPink:const Color(0xFF30201D))),if(done)const Icon(Icons.check,size:12,color:_detailPink)])));
        })),
        if(_selectedEpisode!=null)...[
          const SizedBox(height:14),
          Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:_detailPanel,borderRadius:BorderRadius.circular(15)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('Эпизод ${_episodeNumber(_episodes[_selectedEpisode!],_selectedEpisode!)}',style:const TextStyle(fontWeight:FontWeight.w900)),
            const SizedBox(height:7),const Text('Отметь серию после просмотра. Долгое нажатие на номер серии тоже меняет отметку.',style:TextStyle(color:Color(0xFF927A75),fontSize:12)),
            const SizedBox(height:8),FilledButton.icon(onPressed:()=>_toggleWatched(_selectedEpisode!),icon:Icon(_watched.contains(_episodeNumber(_episodes[_selectedEpisode!],_selectedEpisode!).toString())?Icons.undo:Icons.check),label:Text(_watched.contains(_episodeNumber(_episodes[_selectedEpisode!],_selectedEpisode!).toString())?'Снять отметку':'Отметить просмотренной')),
          ])),
        ],
      ])),
    );
  }
  Widget _chip(String label)=>Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:7),decoration:BoxDecoration(color:_detailPanel,borderRadius:BorderRadius.circular(20)),child:Text(label,style:const TextStyle(fontSize:11,color:Color(0xFF765E59),fontWeight:FontWeight.w700)));
}
