Future<void> _showAddImageModal() async {
  final TextEditingController folderNameController = TextEditingController();
  String selectedCategory = categories[0]; // Categoria padrão
  DateTime selectedDate = DateTime.now(); // Data padrão

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Adicionar Imagem e Criar Pasta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: folderNameController,
                decoration: InputDecoration(hintText: "Nome da Pasta"),
              ),
              DropdownButton<String>(
                value: selectedCategory,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue!;
                  });
                },
                items: categories.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed: _addImage, // Chama a função de upload de imagem
                child: Text('Selecionar Imagem'),
              ),
              SizedBox(height: 10),
              Text('Data: ${selectedDate.toLocal()}'.split(' ')[0]),
              ElevatedButton(
                onPressed: () async {
                  // Aqui você pode implementar um seletor de data
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null && pickedDate != selectedDate) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
                child: Text('Selecionar Data'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              String folderName = folderNameController.text.trim();
              if (folderName.isNotEmpty) {
                _addFolder(folderName, selectedCategory); // Passar a categoria
                Navigator.of(context).pop(); // Fecha o diálogo
              }
            },
            child: Text('Salvar'),
          ),
        ],
      );
    },
  );
}


ElevatedButton(
  onPressed: _showAddImageModal, // Chame o novo método
  child: GestureDetector(
    child: Container(child: Icon(Icons.add_a_photo, size: 50,), decoration: BoxDecoration(),)
  ),
  style: ElevatedButton.styleFrom(
    foregroundColor: Colors.black,
    backgroundColor: Color(0xFFaed513),
    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 30),
  ),
),
