# Теория недели 2: функции и инструменты Python

Модуль заблокирован до полного зачёта недель 0 и 1. Материал можно просматривать заранее, но практику нужно проходить последовательно после допуска.

## 1. Контракт функции

Контракт описывает:

- какие данные функция принимает;
- что означает каждый параметр;
- какие значения допустимы;
- что функция возвращает;
- какие ошибки может вызвать;
- изменяет ли она переданные объекты или внешний мир.

```python
def calculate_total(price: int, quantity: int) -> int:
    """Возвращает стоимость партии автомобилей."""
    if price < 0:
        raise ValueError("price must be non-negative")
    if quantity < 0:
        raise ValueError("quantity must be non-negative")
    return price * quantity
```

Аннотации и docstring описывают ожидания, но сами по себе не проверяют типы и бизнес-правила во время выполнения.

Хорошая функция:

- имеет одну понятную ответственность;
- получает необходимые данные параметрами;
- не зависит от скрытого глобального состояния;
- возвращает предсказуемый результат;
- имеет понятное имя-глагол;
- отделяет вычисление от `input()` и `print()`, если это возможно;
- одинаково ведёт себя на одинаковых аргументах, если функция задумана как чистая.

## 2. Параметры и аргументы

Параметр находится в определении функции, аргумент — в вызове:

```python
def calculate_total(price, quantity):
    return price * quantity


calculate_total(31_000, 2)
```

`price` и `quantity` — параметры. `31_000` и `2` — аргументы.

### Позиционные аргументы

Соотносятся по позиции:

```python
calculate_total(31_000, 2)
```

Порядок важен.

### Именованные аргументы

```python
calculate_total(price=31_000, quantity=2)
```

Они делают вызов понятнее и позволяют менять порядок. Нельзя передать один параметр дважды:

```python
# TypeError
calculate_total(31_000, price=30_000, quantity=2)
```

### Значения по умолчанию

```python
def calculate_final_price(price, discount_percent=0):
    return price - price * discount_percent / 100
```

Параметры без значения по умолчанию идут раньше обычных параметров со значением по умолчанию.

Значение по умолчанию вычисляется **один раз при выполнении `def`**, а не при каждом вызове.

Опасный пример:

```python
def add_model(model, models=[]):
    models.append(model)
    return models
```

Один список используется несколькими вызовами. Безопасный шаблон:

```python
def add_model(model, models=None):
    if models is None:
        models = []
    models.append(model)
    return models
```

При этом функция всё равно изменяет явно переданный список. Контракт должен это сообщать или функция должна создать новый результат.

### Позиционные-only параметры

Символ `/` завершает параметры, которые можно передавать только позиционно:

```python
def percentage(part, total, /):
    return part / total * 100
```

Для недели 2 важно уметь прочитать такую сигнатуру. Использовать её нужно только при понятной причине.

### Keyword-only параметры

После `*` параметры передаются только по имени:

```python
def calculate_price(price, *, discount_percent=0):
    return price - price * discount_percent / 100


calculate_price(31_000, discount_percent=10)
```

Это полезно для флагов и параметров, смысл которых плохо виден из одного числа.

### `*args`

Собирает дополнительные позиционные аргументы в кортеж:

```python
def calculate_sum(*values):
    print(type(values))
    return sum(values)
```

Имя `args` — соглашение. Звёздочка определяет поведение.

Не используй `*args`, если у аргументов разные роли и им нужны понятные имена.

### `**kwargs`

Собирает дополнительные именованные аргументы в словарь:

```python
def build_car_description(model, **details):
    return model, details
```

Не заменяй понятную сигнатуру бесконтрольным `**kwargs`. Он полезен для проксирования аргументов, расширяемых настроек и обёрток.

### Распаковка при вызове

```python
values = (31_000, 2)
total = calculate_total(*values)

arguments = {"price": 31_000, "quantity": 2}
total = calculate_total(**arguments)
```

Ключи словаря должны совпадать с именами параметров. Повтор параметра или неизвестный ключ обычно вызывает `TypeError`.

### Порядок в полной сигнатуре

Общий вид:

```python
def example(positional_only, /, regular, *args, keyword_only, **kwargs):
    ...
```

В прикладном коде не нужно использовать все виды одновременно без необходимости.

## 3. Возврат результатов

### Один результат

```python
def normalize_model(model):
    return model.strip().title()
```

### Несколько результатов

```python
def calculate_range(prices):
    return min(prices), max(prices)


minimum, maximum = calculate_range([10, 20, 30])
```

Функция возвращает один кортеж.

### `None`

Функция без выполненного `return value` возвращает `None`:

```python
def show_message(message):
    print(message)
```

### Ранний возврат

```python
def find_sale(sales, sale_id):
    for sale in sales:
        if sale["id"] == sale_id:
            return sale
    return None
```

Ранний `return` завершает всю функцию, а не только цикл.

### Возврат против изменения аргумента

```python
def add_model_in_place(models, model):
    models.append(model)


def with_added_model(models, model):
    return [*models, model]
```

Обе функции допустимы при ясном контракте. В аналитике часто безопаснее вернуть новый результат.

## 4. Функции как объекты

В Python функцию можно:

- сохранить в переменной;
- передать аргументом;
- вернуть из другой функции;
- хранить в коллекции;
- вызвать позже.

```python
def calculate_total(price, quantity):
    return price * quantity


operation = calculate_total
result = operation(31_000, 2)
```

Без скобок используется сам объект функции. Со скобками выполняется вызов.

### Функция высшего порядка

Принимает или возвращает функцию:

```python
def apply_discount(price, discount_function):
    return discount_function(price)
```

`sorted(..., key=...)`, изученный на неделе 1, является знакомым примером передачи функции.

### `callable()`

```python
print(callable(calculate_total))
```

Проверяет, можно ли объект вызвать. Не гарантирует, что вызов с конкретными аргументами будет корректен.

## 5. Области видимости и пространства имён

Пространство имён сопоставляет имена объектам. Область видимости определяет, где имя доступно напрямую.

Python ищет имя по правилу LEGB:

1. **Local** — текущая функция.
2. **Enclosing** — внешние функции.
3. **Global** — текущий модуль.
4. **Built-in** — встроенные имена.

```python
tax_rate = 0.18


def calculate_tax(price):
    local_result = price * tax_rate
    return local_result
```

`local_result` локален, `tax_rate` найден в global scope.

### Присваивание создаёт локальное имя

```python
discount = 10


def change_discount():
    discount = 20
    return discount
```

Глобальный `discount` не изменился.

### `UnboundLocalError`

```python
counter = 0


def increment():
    print(counter)
    counter += 1
```

Из-за присваивания Python считает `counter` локальным во всей функции, но чтение происходит до локального значения.

### `global`

```python
counter = 0


def increment():
    global counter
    counter += 1
```

Механизм существует, но глобальное изменяемое состояние усложняет тестирование. Для бизнес-кода лучше передавать значение и возвращать результат.

### `nonlocal`

Изменяет имя ближайшей внешней функции:

```python
def make_counter():
    count = 0

    def increment():
        nonlocal count
        count += 1
        return count

    return increment
```

`nonlocal` не ищет глобальное имя; он работает с enclosing scope.

### Built-in имена

Если написать `list = []`, локальное или глобальное имя скроет встроенный `list`. LEGB объясняет, почему вызов `list()` затем ломается.

## 6. Замыкания

Замыкание — функция, которая сохраняет доступ к именам внешней функции после завершения её вызова.

```python
def make_discount(discount_percent):
    def apply(price):
        return price - price * discount_percent / 100

    return apply


loyal_customer_discount = make_discount(10)
result = loyal_customer_discount(31_000)
```

Внешний вызов завершён, но `apply` помнит `discount_percent`.

Замыкание полезно, когда нужно создать настроенную функцию без класса.

### Состояние через `nonlocal`

Замыкание может хранить состояние, но это делает функцию не чистой:

```python
def make_call_counter():
    calls = 0

    def count_call():
        nonlocal calls
        calls += 1
        return calls

    return count_call
```

### Позднее связывание

Функции во closure обычно читают внешнее имя во время вызова, а не копируют его значение при создании.

```python
functions = []

for percent in (5, 10, 15):
    functions.append(lambda price: price * percent / 100)
```

После цикла все lambda могут использовать последнее значение `percent`. Один учебный способ зафиксировать текущее значение — параметр по умолчанию:

```python
lambda price, percent=percent: price * percent / 100
```

Эту особенность нужно понимать, но сложные фабрики функций пока не требуются.

## 7. Декораторы

Декоратор принимает функцию и возвращает функцию, добавляя поведение вокруг вызова.

```python
def announce_call(function):
    def wrapper():
        print("Функция запускается")
        result = function()
        print("Функция завершилась")
        return result

    return wrapper
```

Применение вручную:

```python
say_hello = announce_call(say_hello)
```

Синтаксический сахар:

```python
@announce_call
def say_hello():
    return "Hello"
```

### Передача аргументов

Универсальная обёртка принимает и передаёт аргументы:

```python
def announce_call(function):
    def wrapper(*args, **kwargs):
        result = function(*args, **kwargs)
        return result

    return wrapper
```

Если забыть `return result`, декорированная функция начнёт возвращать `None`.

### `functools.wraps`

Обёртка скрывает имя и docstring оригинальной функции. `wraps` переносит важные метаданные:

```python
from functools import wraps


def announce_call(function):
    @wraps(function)
    def wrapper(*args, **kwargs):
        return function(*args, **kwargs)

    return wrapper
```

Для учебных и production-декораторов `@wraps(function)` считается обязательным.

### Декоратор с параметром

```python
def repeat(times):
    def decorator(function):
        @wraps(function)
        def wrapper(*args, **kwargs):
            result = None
            for _ in range(times):
                result = function(*args, **kwargs)
            return result
        return wrapper
    return decorator
```

Это три уровня функций: конфигурация, приём оригинальной функции, wrapper. На неделе 2 достаточно одного небольшого упражнения.

### Побочные эффекты

Декоратор логирования или измерения времени имеет побочный эффект. Он не должен менять бизнес-результат функции без явно заявленной причины.

## 8. Модули, пакеты и импорт

Модуль — `.py`-файл. Пакет — каталог модулей, обычно с `__init__.py`.

```text
sales_report/
├── __init__.py
├── calculations.py
└── main.py
```

### Импорт модуля

```python
import calculations

result = calculations.calculate_total(31_000, 2)
```

Имя модуля сохраняет происхождение функции.

### Импорт имени

```python
from calculations import calculate_total
```

Удобно, но возможны конфликты имён.

### Alias

```python
import calculations as calc
```

Используй общепонятное или действительно упрощающее имя.

### Wildcard import

```python
from calculations import *
```

Не использовать: трудно понять происхождение имён и легко получить конфликт.

### Код верхнего уровня выполняется при импорте

Если модуль содержит `input()` или запуск `main()` на верхнем уровне, импорт неожиданно начнёт интерактивную программу.

```python
def main():
    ...


if __name__ == "__main__":
    main()
```

При прямом запуске `__name__ == "__main__"`. При импорте `__name__` содержит имя модуля.

### Импорт выполняется один раз за процесс

После первого импорта модуль сохраняется в `sys.modules`; повторный `import` обычно не выполняет верхний уровень заново. Не строй бизнес-логику на повторном импорте.

### Циклический импорт

Если `a.py` импортирует `b.py`, а `b.py` импортирует `a.py`, модули могут увидеть друг друга частично инициализированными. Исправление обычно заключается в пересмотре зависимостей и вынесении общего кода, а не в случайном переносе импортов внутрь функций.

### Абсолютные и относительные импорты

В пакете:

```python
from sales_pipeline.calculations import calculate_total
from .calculations import calculate_total
```

Для учебного проекта выбери один согласованный способ запуска пакета. Запуск модульного приложения через `python -m package.module` часто делает импорты предсказуемее.

### `PYTHONPATH`

Это список каталогов, где Python ищет модули. Не исправляй архитектуру постоянным ручным добавлением путей через `sys.path`. Сначала проверь рабочую директорию, структуру пакета и способ запуска.

### Виртуальное окружение

Виртуальное окружение изолирует интерпретатор и установленные пакеты проекта. Проверяй, что IDE и терминал используют один интерпретатор.

Основные идеи:

- `python -m venv .venv` создаёт окружение;
- `python -m pip ...` запускает pip выбранного Python;
- зависимости устанавливаются только когда нужны;
- `.venv` не копируется в репозиторий;
- точные зависимости будущего приложения фиксируются отдельным файлом/менеджером.

Неделя 2 использует только стандартную библиотеку и не требует установки пакетов.

## 9. Исключения глубже

Исключение сообщает, что функция не может нормально выполнить контракт.

### `raise`

```python
def validate_quantity(quantity):
    if quantity <= 0:
        raise ValueError("quantity must be positive")
    return quantity
```

Не возвращай `0`, `False` или пустой список, если это скрывает реальную ошибку входных данных.

### Свой класс исключения

```python
class InvalidSaleError(ValueError):
    """Продажа нарушает требования входных данных."""
```

Пользовательское исключение должно описывать значимую категорию ошибки. Не создавай новый класс для каждой строки сообщения.

### Иерархия

Лови наиболее конкретный тип раньше общего:

```python
try:
    ...
except FileNotFoundError:
    ...
except OSError:
    ...
```

Пустой `except:` и бездумный `except Exception` могут скрыть дефект программы.

### `else` и `finally`

```python
try:
    data = load_data(path)
except FileNotFoundError:
    print("Файл не найден")
else:
    print("Данные загружены")
finally:
    print("Попытка завершена")
```

- `else` — исключения в `try` не было;
- `finally` — выполняется при любом выходе, включая `return` или другое исключение.

Контекстный менеджер часто лучше ручного `finally` для файлов.

### Повторное возбуждение

```python
try:
    ...
except ValueError:
    print("Добавляем контекст")
    raise
```

Одинокий `raise` сохраняет текущее исключение и traceback.

### Цепочка исключений

```python
try:
    price = int(raw_price)
except ValueError as error:
    raise InvalidSaleError("invalid price") from error
```

`from error` сохраняет исходную причину.

### EAFP и LBYL

- LBYL: сначала проверить, потом выполнить.
- EAFP: выполнить и обработать ожидаемое исключение.

Для преобразования строки в число естественен `try/except ValueError`. Для проверки бизнес-диапазона естественно обычное условие. Не превращай эти подходы в религию.

## 10. Iterable, iterator и iteration protocol

### Iterable

Iterable может предоставить iterator. Примеры: list, tuple, dict, set, str, range, файл.

```python
iterator = iter(["Camry", "X5"])
```

### Iterator

Iterator хранит состояние обхода и возвращает следующий элемент через `next()`:

```python
iterator = iter(["Camry", "X5"])
print(next(iterator))
print(next(iterator))
```

После исчерпания возникает `StopIteration`.

Цикл `for` упрощённо:

1. Вызывает `iter()`.
2. Повторяет `next()`.
3. Останавливается на `StopIteration`.

Обычно `StopIteration` не ловят вручную при обычном `for`.

### Одноразовый обход

Список можно обходить много раз, каждый раз создавая iterator. Один конкретный iterator продолжает с текущей позиции и после исчерпания не «перезапускается».

```python
iterator = iter([1, 2])
list(iterator)
list(iterator)  # пустой список
```

### `iter(iterator) is iterator`

Iterator должен возвращать себя из `iter()`. Iterable вроде списка создаёт новый iterator.

На этой неделе нужно понять поведение, но писать собственный iterator-класс не требуется.

## 11. Генераторы

Генераторная функция содержит `yield`:

```python
def iter_positive_prices(prices):
    for price in prices:
        if price > 0:
            yield price
```

При вызове тело сразу полностью не выполняется. Возвращается generator object. Каждый `next()` продолжает выполнение до следующего `yield`.

### `yield` против `return`

- `yield` выдаёт одно значение и приостанавливает функцию;
- `return` завершает генератор;
- достижение конца также завершает генератор;
- значения не накапливаются автоматически в списке.

### Ленивость

```python
for price in iter_positive_prices(prices):
    print(price)
```

Элемент обрабатывается по мере запроса. Это полезно для больших файлов и pipeline.

Ленивость не означает автоматически «быстрее». Она позволяет уменьшить пиковое потребление памяти и начать обработку раньше.

### Генератор одноразовый

После полного обхода он исчерпан. Для повторения нужно создать новый генератор вызовом функции.

### Generator expression

```python
positive_prices = (price for price in prices if price > 0)
```

Круглые скобки создают ленивое выражение. Это не tuple comprehension.

### `yield from`

```python
def iter_all(groups):
    for group in groups:
        yield from group
```

Передаёт элементы другого iterable. Для недели 2 — обзорно.

### Ошибки генераторов

- ожидать список от вызова generator function;
- использовать генератор дважды;
- вызвать `len()` у генератора;
- проверить membership, а потом ожидать полный последующий обход;
- преобразовать большой поток в list и потерять преимущество ленивости;
- выполнять ресурсозависимый генератор после закрытия файла.

## 12. Контекстные менеджеры

Контекстный менеджер определяет вход и гарантированный выход из ограниченного блока.

```python
with open("sales.json", encoding="utf-8") as file:
    text = file.read()
```

Файл закрывается даже при исключении внутри блока.

### Область действия ресурса

Не возвращай генератор, который пытается лениво читать файл уже после завершения `with`, если файл закрыт. Генератор должен либо сам владеть `with`, либо данные нужно обработать внутри блока.

### Протокол

Класс context manager реализует `__enter__` и `__exit__`. Классы изучаются позже, поэтому сейчас достаточно понимать их назначение.

### `contextlib.contextmanager`

```python
from contextlib import contextmanager


@contextmanager
def announced_operation(name):
    print(f"Start: {name}")
    try:
        yield
    finally:
        print(f"Finish: {name}")
```

До `yield` — вход, после — выход. `try/finally` гарантирует завершающее действие.

Не создавать context manager, если обычная функция яснее и ресурс не требует гарантированного завершения.

## 13. Файлы и `pathlib`

### Пути

```python
from pathlib import Path


data_path = Path(__file__).parent / "data" / "sales.json"
```

Так путь строится относительно файла модуля, а не случайной текущей директории.

### Режимы

- `"r"` — чтение;
- `"w"` — запись с перезаписью;
- `"a"` — добавление в конец;
- `"x"` — создание только нового файла;
- `"b"` — бинарный режим;
- `"t"` — текстовый режим.

Запись через `w` уничтожает прежнее содержимое файла. Перед использованием нужно понимать цель.

### Кодировка

Для учебных текстовых файлов явно указывать:

```python
encoding="utf-8"
```

### Чтение

```python
with path.open("r", encoding="utf-8") as file:
    full_text = file.read()
```

`read()` загружает весь файл. Для большого текстового файла можно обходить строки:

```python
with path.open("r", encoding="utf-8") as file:
    for line in file:
        ...
```

### Запись

```python
with path.open("w", encoding="utf-8") as file:
    file.write("report")
```

`write()` не добавляет `\n` автоматически.

### Проверки пути

```python
path.exists()
path.is_file()
path.parent
path.name
path.suffix
```

Проверка `exists()` не заменяет обработку `FileNotFoundError`: файл может исчезнуть между проверкой и открытием.

## 14. JSON и сериализация

Сериализация преобразует данные в формат хранения или передачи. Десериализация выполняет обратное преобразование.

### JSON

```python
import json


with path.open("r", encoding="utf-8") as file:
    data = json.load(file)
```

`json.load(file)` читает из файла, `json.loads(text)` — из строки.

`json.dump(data, file)` пишет в файл, `json.dumps(data)` возвращает строку.

```python
with path.open("w", encoding="utf-8") as file:
    json.dump(data, file, ensure_ascii=False, indent=2)
```

### Соответствие типов

| JSON | Python после загрузки |
|---|---|
| object | `dict` |
| array | `list` |
| string | `str` |
| integer | `int` |
| number с дробью | обычно `float` |
| true/false | `True`/`False` |
| null | `None` |

Не каждый Python-объект сериализуется в JSON автоматически. Например, `set`, `Decimal` и произвольный класс требуют явного преобразования или настройки encoder.

Повреждённый JSON вызывает `json.JSONDecodeError`, являющийся разновидностью `ValueError`.

### JSON не выполняет код

JSON — формат данных. Но загруженные данные всё равно недоверенные: нужно проверять типы, обязательные поля и бизнес-правила.

### `pickle`

`pickle` сохраняет многие Python-объекты, но его загрузка способна выполнить опасный код. Никогда не вызывать `pickle.load()` или `pickle.loads()` для недоверенных данных.

Для API и переносимых данных обычно выбирают JSON или другой явно определённый формат. В неделе 2 `pickle` изучается только концептуально и на безопасном локальном примере без загрузки внешнего файла.

## 15. `Decimal` для денег

```python
from decimal import Decimal


price = Decimal("31000.00")
discount = Decimal("0.10")
final_price = price * (Decimal("1") - discount)
```

Создавай десятичные значения из строк:

```python
Decimal("0.1")
```

Создание из `float` переносит его двоичную погрешность:

```python
Decimal(0.1)
```

### Округление

```python
from decimal import Decimal, ROUND_HALF_UP


money = value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
```

Правило округления является частью требований бизнеса. Не выбирать его молча для реального финансового приложения.

### JSON и Decimal

Стандартный `json` не записывает `Decimal` автоматически. Простой безопасный учебный вариант — хранить денежные значения в JSON строками и преобразовывать их после валидации.

```json
{"price": "31000.00"}
```

## 16. `is`, `==` и интернирование

`==` спрашивает: равны ли значения. `is` спрашивает: один ли это объект.

```python
first = [1, 2]
second = [1, 2]

first == second  # True
first is second  # False
```

Использовать `is` для `None`:

```python
value is None
```

Не использовать `is` для сравнения строк, чисел или бизнес-значений. Интерпретатор может повторно использовать некоторые малые числа или строки — интернирование. Это деталь реализации, на которую нельзя опирать логику.

## 17. Минимальное логирование

`print()` подходит для интерфейса учебной консольной программы. Логи описывают события для разработчика и эксплуатации.

```python
import logging


logger = logging.getLogger(__name__)


def process_sale(sale):
    logger.info("Processing sale id=%s", sale["id"])
```

Настройку выполняют один раз в точке входа:

```python
logging.basicConfig(level=logging.INFO)
```

Уровни:

- `DEBUG` — подробная диагностика;
- `INFO` — нормальные важные события;
- `WARNING` — необычная ситуация без остановки;
- `ERROR` — операция не выполнена;
- `CRITICAL` — серьёзная проблема всего приложения.

Не использовать f-string для дорогого форматирования логов без необходимости; передача аргументов позволяет logging отложить форматирование.

Не записывать в лог пароли, токены и чувствительные личные данные.

## 18. Архитектура pipeline

Итоговая программа разделяется на этапы:

```text
путь → чтение JSON → проверка структуры → преобразование денег
     → ленивый отбор корректных записей → агрегаты → отчёт
```

Каждая граница имеет собственную ответственность:

- `io_utils` читает и записывает;
- `validators` проверяет запись и создаёт понятное исключение;
- `calculations` считает и не знает о файлах;
- `decorators` содержит общее наблюдаемое поведение;
- `main` связывает части и определяет обработку ошибок для пользователя.

Ошибка чтения файла, повреждённый JSON и недопустимая продажа — разные ситуации. Они не должны превращаться в одно молчаливое значение `[]`.

Генератор должен позволять обрабатывать записи по одной. Но обычный JSON array стандартный `json.load()` всё равно загружает документ целиком. В неделе 2 «ленивость» относится к последующей обработке записей; настоящее потоковое чтение огромного JSON потребует другого формата или инструмента и будет позже.

## 19. Типичные ошибки

- изменяемое значение параметра по умолчанию;
- использование `*args` вместо понятных параметров;
- потеря `return` в wrapper;
- отсутствие `@wraps`;
- изменение global state без необходимости;
- путаница `global` и `nonlocal`;
- позднее связывание переменной в closure;
- `input()` на верхнем уровне импортируемого модуля;
- wildcard import;
- ручное изменение `sys.path` вместо исправления структуры;
- циклические импорты;
- ловля слишком широкого исключения;
- потеря исходной причины при создании нового исключения;
- попытка повторно обойти исчерпанный generator;
- ожидание `len(generator)`;
- чтение генератора после закрытия ресурса;
- отсутствие `encoding="utf-8"`;
- случайная перезапись файла режимом `w`;
- путаница `json.load` и `json.loads`;
- доверие структуре загруженного JSON;
- загрузка недоверенного pickle;
- создание `Decimal` из float;
- сравнение значений через `is`;
- логирование секретов или подмена пользовательского вывода логами.

## 20. Контрольные прогнозы

До запуска запиши ожидаемый результат.

### Прогноз 1

```python
def add_model(model, models=[]):
    models.append(model)
    return models


print(add_model("Camry"))
print(add_model("X5"))
```

### Прогноз 2

```python
def show(*args, **kwargs):
    print(type(args), args)
    print(type(kwargs), kwargs)


show("Camry", 31_000, active=True)
```

### Прогноз 3

```python
value = "global"


def outer():
    value = "enclosing"

    def inner():
        value = "local"
        return value

    return inner()


print(outer())
```

### Прогноз 4

```python
def decorator(function):
    def wrapper(*args, **kwargs):
        function(*args, **kwargs)
    return wrapper


@decorator
def calculate():
    return 42


print(calculate())
```

### Прогноз 5

```python
iterator = iter([1, 2])
print(next(iterator))
print(list(iterator))
print(list(iterator))
```

### Прогноз 6

```python
def numbers():
    print("start")
    yield 1
    print("middle")
    yield 2


generator = numbers()
print("created")
print(next(generator))
```

### Прогноз 7

```python
from decimal import Decimal

print(Decimal("0.1"))
print(Decimal(0.1))
```

### Прогноз 8

```python
first = [1, 2]
second = [1, 2]
alias = first

print(first == second)
print(first is second)
print(first is alias)
```

## 21. Что будет позже

- полноценные type hints и mypy;
- `dataclass`, Protocol и ООП;
- pytest и fixtures;
- async generators;
- собственные iterator/context-manager классы;
- потоковые JSON-парсеры;
- структурированное production-логирование;
- dependency management проекта;
- чтение данных из PostgreSQL и Django ORM.

## 22. Официальные источники

- [Defining Functions](https://docs.python.org/3/tutorial/controlflow.html#defining-functions);
- [Scopes and Namespaces](https://docs.python.org/3/tutorial/classes.html#python-scopes-and-namespaces);
- [Modules](https://docs.python.org/3/tutorial/modules.html);
- [Errors and Exceptions](https://docs.python.org/3/tutorial/errors.html);
- [Iterators](https://docs.python.org/3/tutorial/classes.html#iterators);
- [Generator expressions](https://docs.python.org/3/reference/expressions.html#generator-expressions);
- [functools.wraps](https://docs.python.org/3/library/functools.html#functools.wraps);
- [contextlib](https://docs.python.org/3/library/contextlib.html);
- [pathlib](https://docs.python.org/3/library/pathlib.html);
- [json](https://docs.python.org/3/library/json.html);
- [pickle](https://docs.python.org/3/library/pickle.html);
- [decimal](https://docs.python.org/3/library/decimal.html).
