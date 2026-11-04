import 'package:flutter/material.dart';
import 'library_store.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key,required this.onOpenAnime});
  final ValueChanged<String> onOpenAnime;
  @override
  State<HistoryScreen> createState()=>_HistoryScreenState();
}
class _HistoryScreenState extends State<HistoryScreen>{
  List<Map<String,String>> _items=[];
  bool _loading=true;
  @override
  void initState(){super.initState();_load();}
  Future<void> _load() async {final v=await KairoLibrary.history();if(mounted)setState(()=>{_items=v,_loading=false});}
  Future<void> _clear() async {await KairoLibrary.clearHistory();if(mounted)setState(()=>_items=[]);}
  @override
  Widget build(BuildContext context)=>Scaffold(
    backgroundColor:const Color(0xFFFFF3F0),
    appBar:AppBar(title:const Text('История просмотров'),backgroundColor:const Color(0xFFFFF3F0),
      actions:[IconButton(onPressed:_items.isEmpty?null:()=>showDialog(context:context,builder:(ctx)=>AlertDialog(
        title:const Text('Очистить историю?'),content:const Text('История просмотров будет удалена с этого устройства.'),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Отмена')),FilledButton(onPressed:(){Navigator.pop(ctx);_clear();},child:const Text('Очистить'))])),icon:const Icon(Icons.delete_sweep_rounded))]),
    body:_loading?const Center(child:CircularProgressIndicator(color:Color(0xFFEF7166))):
      _items.isEmpty?const Center(child:Text('История пока пуста')):RefreshIndicator(onRefresh:_load,color:const Color(0xFFEF7166),
        child:ListView.separated(padding:const EdgeInsets.all(15),itemCount:_items.length,separatorBuilder:(_,__)=>const SizedBox(height:8),
          itemBuilder:(ctx,i){final x=_items[i];return Card(color:Colors.white,child:ListTile(
            onTap:()=>widget.onOpenAnime(x['id']??''),
            leading:ClipRRect(borderRadius:BorderRadius.circular(8),child:SizedBox(width:48,height:64,
              child:(x['poster']??'').startsWith('http')?Image.network(x['poster']!,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.movie)):const Icon(Icons.movie))),
            title:Text(x['title']??'Аниме',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800)),
            subtitle:Text('Открыто: ${_date(x['opened'])}'),
            trailing:const Icon(Icons.chevron_right_rounded),
          ));})),
  );
  String _date(String? raw){final d=DateTime.tryParse(raw??'')?.toLocal();if(d==null)return 'недавно';return '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';}
}
