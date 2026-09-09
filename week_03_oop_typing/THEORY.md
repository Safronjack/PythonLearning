# Теория недели 3: ООП, typing и качество кода

Этот конспект рассчитан на первое системное знакомство с объектно-ориентированным программированием. Не пытайся запомнить всё за один проход. Для каждого дня читай только указанные главы, перепечатывай маленькие примеры и объясняй результат своими словами.

## 1. Зачем нужны объекты

До этой недели данные автомобиля можно было хранить в словаре, а операции — в отдельных функциях:

```python
from decimal import Decimal

car = {
    "vin": "VIN-001",
    "model": "Camry",
    "price": Decimal("31000.00"),
}


def describe_car(car_data: dict) -> str:
    return f"{car_data['model']} — {car_data['price']}"
```

Для маленькой программы этого достаточно. По мере роста проекта появляются проблемы:

- разные словари получают разные ключи;
- правило допустимой цены приходится помнить во всех функциях;
- непонятно, какие операции относятся именно к автомобилю;
- состояние легко изменить в обход бизнес-правил.

Объект объединяет связанные данные и поведение. Класс описывает, какие объекты можно создать и какие операции они поддерживают.

ООП — инструмент моделирования, а не обязательная замена каждой функции. Простое вычисление часто лучше оставить чистой функцией.

## 2. Класс, объект и экземпляр

Класс — объект Python, который описывает создание и поведение экземпляров. Экземпляр — конкретный объект, созданный вызовом класса.

```python
class Car:
    pass


first_car = Car()
second_car = Car()

print(type(first_car))
print(first_car is second_car)
```

`first_car` и `second_car` имеют один тип, но разную идентичность. Удобная модель объекта:

- identity — какой именно это объект;
- type — какие операции он поддерживает;
- state — какие значения сейчас хранят его атрибуты.

`id()` помогает наблюдать идентичность в учебном эксперименте, но бизнес-логика не должна сохранять или сравнивать конкретные числовые значения `id()`.

### `isinstance()`

```python
print(isinstance(first_car, Car))
```

`type(value) is Car` проверяет точный тип. `isinstance(value, Car)` также учитывает наследников и обычно лучше соответствует полиморфному коду.

## 3. Атрибуты, методы и `self`

Атрибут — имя, доступное через точку. Он может хранить данные или ссылаться на функцию/метод.

```python
from decimal import Decimal


class Car:
    category = "vehicle"

    def __init__(self, vin: str, model: str, price: Decimal) -> None:
        self.vin = vin
        self.model = model
        self.price = price

    def describe(self) -> str:
        return f"{self.model} ({self.vin}) — {self.price}"


car = Car("VIN-001", "Camry", Decimal("31000.00"))
print(car.model)
print(car.describe())
```

`self` — обычный параметр, в который при вызове связанного метода Python передаёт конкретный экземпляр. Записи ниже по смыслу близки:

```python
car.describe()
Car.describe(car)
```

Имя `self` не является ключевым словом, но использовать другое имя нельзя по принятому стилю: код станет неожиданным для всех Python-разработчиков.

### Что делает `__init__`

`__init__` инициализирует уже созданный экземпляр. В разговорной речи его часто называют конструктором, но фактическое создание объекта выполняет `__new__`. На этой неделе переопределять `__new__` не нужно.

`__init__` должен возвращать `None`. Явный возврат другого значения вызывает `TypeError`.

### Пространство имён экземпляра

Для обычного пользовательского объекта атрибуты часто можно увидеть через `vars()`:

```python
print(vars(car))
```

Это полезный учебный инструмент, но внешний код не должен постоянно обходить публичные методы и редактировать `vars(object)`.

## 4. Атрибут экземпляра и атрибут класса

Атрибут, записанный через `self`, обычно принадлежит экземпляру. Атрибут в теле класса общий для класса и используется как значение по умолчанию при поиске.

```python
class Dealership:
    business_kind = "car sales"

    def __init__(self, name: str) -> None:
        self.name = name
```

Поиск `dealership.business_kind` сначала проверяет экземпляр, затем класс и его базовые классы.

### Затенение атрибута класса

```python
first = Dealership("North")
second = Dealership("South")

first.business_kind = "premium car sales"

print(first.business_kind)
print(second.business_kind)
print(Dealership.business_kind)
```

Присваивание через `first` создало атрибут экземпляра и затенило значение класса только для него.

### Опасный общий изменяемый атрибут

```python
class BrokenInventory:
    cars = []


first = BrokenInventory()
second = BrokenInventory()
first.cars.append("VIN-001")
print(second.cars)
```

Оба экземпляра находят один список в классе. Независимое изменяемое состояние создавай в `__init__`:

```python
class Inventory:
    def __init__(self) -> None:
        self.cars: list[str] = []
```

Атрибуты класса подходят для настоящих общих констант и осознанного состояния класса, но не для случайного хранения данных экземпляров.

## 5. Инварианты и валидное состояние

Инвариант — правило, которое должно оставаться истинным для каждого допустимого состояния объекта. Примеры:

- цена автомобиля положительна;
- баланс покупателя неотрицателен;
- VIN непустой;
- проданный автомобиль нельзя продать повторно.

Проверка только в одном внешнем скрипте недостаточна: другой код сможет создать некорректный объект.

```python
from decimal import Decimal


class Car:
    def __init__(self, vin: str, price: Decimal) -> None:
        if not vin.strip():
            raise ValueError("VIN cannot be empty")
        if price <= Decimal("0"):
            raise ValueError("price must be positive")

        self.vin = vin.strip()
        self.price = price
```

Сразу после успешного `__init__` объект должен быть готов к использованию. Не создавай «наполовину заполненный» объект, который требует обязательного вызова `setup()`.

### Команда должна сохранить инвариант

```python
class Customer:
    def __init__(self, balance: Decimal) -> None:
        if balance < Decimal("0"):
            raise ValueError("balance cannot be negative")
        self._balance = balance

    def withdraw(self, amount: Decimal) -> None:
        if amount <= Decimal("0"):
            raise ValueError("amount must be positive")
        if amount > self._balance:
            raise ValueError("insufficient funds")
        self._balance -= amount
```

Метод не только меняет данные, но и защищает правило объекта.

## 6. Инкапсуляция и соглашения имён

Инкапсуляция означает, что объект скрывает детали хранения и предоставляет понятные операции. В Python это прежде всего соглашение и дизайн интерфейса, а не непробиваемая защита.

- `name` — публичная часть интерфейса;
- `_name` — внутренняя деталь, которую внешний код не должен менять напрямую;
- `__name` — включает name mangling, усложняя случайный конфликт имён в наследниках;
- `__name__` — специальное имя протокола Python; придумывать свои «магические» имена не нужно.

Name mangling не делает значение секретным и не обеспечивает безопасность. `__balance` преобразуется примерно в `_Customer__balance`.

### Не писать Java-style getters без причины

Если простое поле можно безопасно читать и менять, публичный атрибут допустим. Не обязательно заранее создавать `get_model()` и `set_model()` для каждого значения.

Свойство полезно, когда при чтении или записи есть правило, вычисление или необходимость сохранить стабильный публичный интерфейс.

## 7. `property`

```python
from decimal import Decimal


class Customer:
    def __init__(self, balance: Decimal) -> None:
        self._balance = Decimal("0")
        self.balance = balance

    @property
    def balance(self) -> Decimal:
        return self._balance

    @balance.setter
    def balance(self, value: Decimal) -> None:
        if value < Decimal("0"):
            raise ValueError("balance cannot be negative")
        self._balance = value
```

Внешний код использует `customer.balance`, но запись проходит через setter. Так можно сохранить привычный интерфейс атрибута и централизовать правило.

Не превращай каждое поле в property автоматически. И не помещай в property неожиданно тяжёлую работу, сетевой запрос или изменение другого объекта: чтение атрибута ожидается дешёвым и предсказуемым.

### Read-only property

Если setter отсутствует, присваивание свойству запрещено обычным публичным способом:

```python
class Sale:
    def __init__(self, subtotal: Decimal, discount: Decimal) -> None:
        self._subtotal = subtotal
        self._discount = discount

    @property
    def total(self) -> Decimal:
        return self._subtotal - self._discount
```

## 8. Instance-, class- и static-методы

### Instance method

Получает `self` и работает с конкретным экземпляром.

```python
class Car:
    def rename(self, model: str) -> None:
        self.model = model
```

### Class method

Получает `cls`. Частое применение — альтернативный способ создания объекта.

```python
class Car:
    def __init__(self, vin: str, model: str) -> None:
        self.vin = vin
        self.model = model

    @classmethod
    def from_dict(cls, data: dict[str, str]) -> "Car":
        return cls(vin=data["vin"], model=data["model"])
```

Использование `cls`, а не жёсткого `Car`, позволяет методу корректнее работать с наследниками.

### Static method

Не получает ни `self`, ни `cls`. Это функция, помещённая в namespace класса, потому что тесно относится к его смыслу.

```python
class Car:
    @staticmethod
    def is_valid_vin(vin: str) -> bool:
        return len(vin.strip()) >= 5
```

Если функция нужна нескольким несвязанным классам, обычная функция модуля часто лучше static method.

## 9. Отношения между объектами

### Ассоциация

Объекты временно взаимодействуют, но один необязательно хранит другой:

```python
class ReceiptPrinter:
    def print_receipt(self, sale: "Sale") -> None:
        print(sale)
```

### Агрегация

Один объект содержит ссылку на другой, но оба могут существовать независимо. Например, автосалон сотрудничает с поставщиком, который существует и без него.

### Композиция

Один объект состоит из частей и управляет ими как единым целым. Например, `Dealership` владеет своим `Inventory`.

```python
class Inventory:
    def __init__(self) -> None:
        self._cars: list[Car] = []


class Dealership:
    def __init__(self, name: str) -> None:
        self.name = name
        self.inventory = Inventory()
```

В Python граница композиции и агрегации не задаётся отдельным синтаксисом. Важны смысл владения и жизненный цикл.

## 10. Наследование

Наследование выражает отношение «является»: `Truck` является `Vehicle`. Оно позволяет наследнику использовать и переопределять поведение базового класса.

```python
class Vehicle:
    def describe(self) -> str:
        return "Vehicle"


class PassengerCar(Vehicle):
    def describe(self) -> str:
        return "Passenger car"
```

Наследование не нужно только ради повторного использования пары строк. Если отношение «является» звучит неестественно, чаще подходит композиция.

Плохая идея: `Dealership(list)`. Автосалон не является списком; у него есть склад.

### Переопределение

Наследник может дать свою реализацию метода, сохранив смысл контракта. Если базовый `total()` обещает неотрицательный `Decimal`, наследник не должен внезапно возвращать строку или отрицательное число.

## 11. Полиморфизм и duck typing

Полиморфизм позволяет одинаково обращаться с объектами разных типов, если они выполняют общий контракт.

```python
class ConsoleNotifier:
    def send(self, message: str) -> None:
        print(message)


class MemoryNotifier:
    def __init__(self) -> None:
        self.messages: list[str] = []

    def send(self, message: str) -> None:
        self.messages.append(message)


def notify_sale(notifier, message: str) -> None:
    notifier.send(message)
```

Функции важен метод `send`, а не точное происхождение объекта. Это называют duck typing: важнее поддерживаемое поведение, чем формальная родословная.

Полиморфный код обычно не должен строить длинную цепочку `if type(...) is ...` для каждого варианта.

## 12. Абстрактные базовые классы

ABC фиксирует обязательные операции номинальной иерархии.

```python
from abc import ABC, abstractmethod
from decimal import Decimal


class DiscountPolicy(ABC):
    @abstractmethod
    def calculate_discount(self, subtotal: Decimal) -> Decimal:
        raise NotImplementedError


class NoDiscount(DiscountPolicy):
    def calculate_discount(self, subtotal: Decimal) -> Decimal:
        return Decimal("0")
```

Создать экземпляр класса с нереализованным abstract method нельзя. Тело метода может содержать `raise NotImplementedError`, но именно `@abstractmethod` сообщает Python, что класс абстрактный.

ABC подходит, если нужна явная иерархия. Позже `Protocol` позволит описать структурный контракт без наследования.

## 13. `dataclass`

Классы данных часто хранят значения и почти не содержат сложного поведения. `@dataclass` генерирует часть шаблонного кода.

```python
from dataclasses import dataclass
from decimal import Decimal


@dataclass
class SaleLine:
    vin: str
    price: Decimal
    quantity: int = 1
```

Обычно будут сгенерированы `__init__`, `__repr__` и `__eq__`. Это не означает, что dataclass является просто словарём: это обычный класс.

### Изменяемые значения и `default_factory`

```python
from dataclasses import dataclass, field


@dataclass
class InventorySnapshot:
    vins: list[str] = field(default_factory=list)
```

Фабрика создаёт новый список для каждого экземпляра.

### `frozen=True`

```python
@dataclass(frozen=True)
class SaleReceipt:
    sale_id: int
    total: Decimal
```

Обычное присваивание полю запрещается. Это полезно для value object, но не превращает содержимое глубоко в неизменяемое. Если frozen dataclass содержит список, сам список всё ещё можно менять.

### `__post_init__`

После сгенерированного `__init__` можно проверить связанные поля:

```python
@dataclass(frozen=True)
class Percentage:
    value: int

    def __post_init__(self) -> None:
        if not 0 <= self.value <= 100:
            raise ValueError("percentage must be between 0 and 100")
```

Не используй dataclass автоматически для сервисов, которые в основном выполняют операции и имеют зависимости.

## 14. `Enum`

Enum задаёт конечный набор именованных значений.

```python
from enum import Enum


class CarStatus(Enum):
    AVAILABLE = "available"
    RESERVED = "reserved"
    SOLD = "sold"


status = CarStatus.AVAILABLE
print(status is CarStatus.AVAILABLE)
print(status.name)
print(status.value)
```

Enum защищает от случайных строк вроде `"selled"`. Для получения элемента из внешней строки можно вызвать `CarStatus(raw_value)` и обработать `ValueError` на границе ввода.

Внутри модели храни `CarStatus`, а в JSON позднее преобразуй его в `.value`.

## 15. Магические методы и протоколы Python

Имена вида `__name__` вызываются синтаксисом и встроенными функциями Python. Их не следует вызывать напрямую без учебной причины.

| Операция | Метод |
|---|---|
| `str(obj)` / `print(obj)` | `__str__` |
| `repr(obj)` / отображение в контейнере | `__repr__` |
| `left == right` | `__eq__` |
| `hash(obj)` / ключ dict | `__hash__` |
| `len(obj)` | `__len__` |
| `item in obj` | `__contains__` или итерация |
| `iter(obj)` | `__iter__` |
| `bool(obj)` | `__bool__`, иначе `__len__` |
| `obj()` | `__call__` |

Специальные методы образуют протоколы. Например, объект может стать iterable, если корректно реализует `__iter__`.

### `__repr__` и `__str__`

```python
class Car:
    def __init__(self, vin: str, model: str) -> None:
        self.vin = vin
        self.model = model

    def __repr__(self) -> str:
        return f"Car(vin={self.vin!r}, model={self.model!r})"

    def __str__(self) -> str:
        return f"{self.model} [{self.vin}]"
```

`repr` предназначен прежде всего разработчику и отладке. `str` — человеку. Хороший `repr` однозначен и показывает важное состояние; пароль, токен и другие секреты туда не помещают.

Если `__str__` отсутствует, Python может использовать `__repr__` как запасной вариант.

### `__eq__` и `NotImplemented`

```python
class Car:
    def __init__(self, vin: str) -> None:
        self.vin = vin

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Car):
            return NotImplemented
        return self.vin == other.vin
```

`NotImplemented` — специальный результат бинарной операции: Python может попробовать отражённую операцию второго объекта или решить, что объекты не равны. Это не то же самое, что исключение `NotImplementedError`.

Сравнивать нужно по стабильной смысловой идентичности или по полному значению value object. Выбор «все поля подряд» не всегда правилен.

## 16. Равенство и хеширование

Для hashable объектов должно выполняться:

```text
если a == b, то hash(a) == hash(b)
```

Обратное неверно: одинаковый hash ещё не доказывает равенство.

Если переопределить `__eq__` в обычном изменяемом классе, Python обычно делает экземпляры нехешируемыми. Это защищает set/dict от объекта, чьи поля равенства меняются после помещения в хеш-таблицу.

Безопасный вариант для небольшого value object:

```python
from dataclasses import dataclass


@dataclass(frozen=True)
class Vin:
    value: str
```

Не добавляй `unsafe_hash=True`, пока не можешь доказать, что поля равенства не изменятся.

## 17. Свой контейнерный интерфейс

```python
from collections.abc import Iterator


class Inventory:
    def __init__(self) -> None:
        self._cars: list[Car] = []

    def add(self, car: Car) -> None:
        self._cars.append(car)

    def __len__(self) -> int:
        return len(self._cars)

    def __iter__(self) -> Iterator[Car]:
        return iter(self._cars)

    def __contains__(self, car: object) -> bool:
        return car in self._cars
```

Теперь `len(inventory)`, цикл и `car in inventory` используют привычный синтаксис. Реализуй только операции, которые естественны для сущности. Не нужно делать каждый класс «похожим на список».

Не возвращай внутренний изменяемый список напрямую, если внешний код не должен менять его в обход `add()`/`remove()`.

## 18. MRO и `super()`

MRO — method resolution order, порядок поиска атрибутов в классе и его базовых классах.

```python
class Root:
    pass


class Left(Root):
    pass


class Right(Root):
    pass


class Child(Left, Right):
    pass


print(Child.mro())
```

При множественном наследовании Python строит согласованный порядок, в котором каждый класс встречается один раз.

### `super()` — следующий класс по MRO

`super()` не означает буквально «мой прямой родитель». Он создаёт объект-посредник, который продолжает поиск после текущего класса в MRO.

```python
class Base:
    def describe(self) -> str:
        return "base"


class Named(Base):
    def describe(self) -> str:
        return f"named -> {super().describe()}"
```

### Cooperative multiple inheritance

В ромбовидной иерархии каждый участник должен использовать совместимый контракт и передавать дальнейшую работу через `super()`. Один прямой вызов вроде `Root.__init__(self)` способен обойти часть MRO или вызвать общий базовый код дважды.

Для учебного mixin:

- одна узкая ответственность;
- обычно не является самостоятельной сущностью;
- не хранит неожиданное сложное состояние;
- использует `super()`, если участвует в цепочке одноимённых методов;
- название часто заканчивается на `Mixin`.

Множественное наследование не является целью. Если цепочку трудно объяснить по `mro()`, композиция обычно проще.

## 19. Принцип подстановки

Наследник должен быть пригоден там, где ожидается базовый тип, не ломая обещанный контракт. Это практический смысл Liskov Substitution Principle.

Нарушения:

- базовый метод принимает любое положительное количество, а наследник только чётное без причины в контракте;
- базовый метод возвращает `Decimal`, наследник — строку;
- базовый метод не меняет аргумент, наследник внезапно меняет;
- наследник выбрасывает новое неожиданное исключение в обычном сценарии.

Иногда обнаружение такого нарушения означает, что между классами вообще нет корректного отношения наследования.

## 20. Аннотации типов

Аннотация описывает ожидание для людей, IDE и статического анализатора. Обычный Python не запрещает передать другое значение автоматически.

```python
from decimal import Decimal


def calculate_total(price: Decimal, quantity: int) -> Decimal:
    return price * quantity
```

### Основные формы

```python
def find_car(vin: str) -> Car | None:
    ...


def index_by_vin(cars: list[Car]) -> dict[str, Car]:
    ...


def mark_sold(vins: set[str]) -> None:
    ...
```

`Car | None` означает, что результат может быть объектом или `None`. Код обязан проверить `None` до обращения к атрибутам.

Для параметра часто полезно обещать только необходимую возможность:

```python
from collections.abc import Iterable


def total_prices(cars: Iterable[Car]) -> Decimal:
    ...
```

Функции не нужен именно list, ей нужен любой iterable.

### `Any` и `object`

`Any` просит type checker почти не проверять операции. `object` означает «значение неизвестного типа», и перед специальной операцией его нужно сузить проверкой. Для границы JSON `object` или точный рекурсивный alias честнее, но иногда учебный код начинает с ограниченного `Any` и постепенно уточняется.

Не используй `Any`, чтобы заставить предупреждения исчезнуть.

### Alias

```python
CarIndex = dict[str, Car]
```

Такой alias совместим с Python 3.11, который сейчас используется в учебном окружении. Отдельный синтаксис `type CarIndex = ...`, появившийся в более новых версиях Python, пока не нужен. Перед применением нового синтаксиса всегда учитывай минимальную версию проекта.

### `ClassVar`

Аннотация `ClassVar` явно показывает статическому анализатору, что имя относится к классу, а не к полю каждого экземпляра:

```python
from typing import ClassVar


class Car:
    category: ClassVar[str] = "vehicle"
```

Это не меняет runtime-механику поиска атрибутов, но точнее описывает намерение.

## 21. `Protocol`

Protocol описывает структурный контракт: класс совместим, если предоставляет нужные атрибуты и методы. Наследоваться от протокола явно необязательно.

```python
from decimal import Decimal
from typing import Protocol


class DiscountPolicy(Protocol):
    def calculate_discount(self, subtotal: Decimal) -> Decimal:
        ...


class NoDiscount:
    def calculate_discount(self, subtotal: Decimal) -> Decimal:
        return Decimal("0")
```

`NoDiscount` подходит статически, хотя не наследуется от `DiscountPolicy`.

Protocol особенно полезен на границе зависимости: сервису важна операция, а не конкретная реализация.

Обычный Protocol в первую очередь предназначен для статической проверки. Не применяй к нему `isinstance()` без осознанного `@runtime_checkable`; даже с этим декоратором runtime-проверка не проверяет точные сигнатуры так же глубоко, как type checker.

## 22. `Callable` и зависимости-функции

Зависимость не обязана быть объектом со множеством методов. Иногда достаточно функции:

```python
from collections.abc import Callable

Notifier = Callable[[str], None]


def complete_sale(message: str, notify: Notifier) -> None:
    notify(message)
```

Выбирай форму по размеру контракта: одна операция может быть `Callable`, несколько связанных операций — Protocol или класс.

## 23. SOLID без ритуалов

SOLID — пять ориентиров для дизайна. Они не требуют создавать интерфейс на каждый класс.

### S — Single Responsibility Principle

У модуля или класса должна быть одна осмысленная причина измениться. `PurchaseService` принимает решение о покупке; CLI читает ввод; printer форматирует вывод.

«Одна ответственность» не означает «один метод». Важно объединить поведение, меняющееся по одной причине.

### O — Open/Closed Principle

Поведение желательно расширять новой реализацией контракта, не переписывая стабильный сервис. Новая скидочная политика может реализовать тот же Protocol.

### L — Liskov Substitution Principle

Реализация не нарушает ожидания общего контракта.

### I — Interface Segregation Principle

Клиент не должен зависеть от операций, которые ему не нужны. Маленький `Notifier.send()` лучше огромного `ApplicationServices` для компонента, который лишь отправляет уведомление.

### D — Dependency Inversion Principle

Высокоуровневая бизнес-логика зависит от контракта, а не от конкретной инфраструктуры.

SOLID помогает находить реальные точки изменения. Слишком много абстракций для одной неизменяемой операции ухудшает код.

## 24. Dependency injection и inversion of control

Dependency — объект или функция, необходимые другому объекту для работы. Dependency injection означает передачу зависимости снаружи.

```python
class PurchaseService:
    def __init__(self, discount_policy: DiscountPolicy) -> None:
        self._discount_policy = discount_policy
```

Сервис не создаёт `NoDiscount()` внутри себя и не выбирает конкретный класс по глобальной настройке. Точка сборки решает, какую реализацию передать:

```python
policy = NoDiscount()
service = PurchaseService(discount_policy=policy)
```

Это и есть простая форма inversion of control: выбор реализации вынесен из бизнес-класса наружу.

Преимущества:

- зависимость видна в конструкторе;
- реализацию можно заменить;
- тест может передать маленькую fake-реализацию;
- сервис не зависит от консоли, сети или Django.

Не используй глобальный service locator как скрытую замену явным зависимостям.

## 25. Сущность, value object и сервис

Это не специальные конструкции Python, а полезные роли модели.

- Entity имеет устойчивую идентичность во времени: автомобиль с VIN, покупатель с id.
- Value object определяется своими значениями: процент скидки, денежная сумма, адрес. Часто удобен frozen dataclass.
- Service выполняет бизнес-операцию, которая естественно не принадлежит одной сущности: оформление покупки между покупателем, автомобилем и политикой скидок.

Не делай один `Manager`, который читает ввод, меняет все объекты, пишет JSON и печатает отчёт. Такой класс имеет слишком много причин измениться.

## 26. Атомарность операции в памяти

Даже без базы данных можно не оставлять частично изменённое состояние.

Опасный порядок:

```text
1. списать деньги;
2. обнаружить, что машина уже продана;
3. выбросить исключение.
```

Безопаснее для учебной модели:

```text
1. проверить все предусловия;
2. вычислить итог;
3. только после успешных проверок изменить связанные объекты;
4. вернуть неизменяемый receipt.
```

В реальной базе данных эту задачу позже решат транзакции и блокировки, но правильную границу бизнес-операции нужно увидеть уже сейчас.

## 27. Метаклассы и дескрипторы — только обзор

Класс сам является объектом. Обычно его класс — `type`:

```python
class Car:
    pass


print(type(Car))
```

Метакласс управляет созданием классов примерно так, как класс управляет созданием экземпляров. Фреймворки могут использовать этот механизм, но писать собственный метакласс на этой неделе не нужно.

Дескриптор — объект класса с методами протокола `__get__`, `__set__` или `__delete__`. Функции, методы и `property` связаны с дескрипторным протоколом. На этой неделе достаточно понимать, что доступ `object.attribute` может запускать протокол, а не просто читать словарь.

Глубокий порядок поиска атрибутов, data/non-data descriptors, `__set_name__`, пользовательские метаклассы и hooks создания класса находятся в отложенном backlog.

## 28. Архитектура итоговой модели

```text
main.py
  создаёт зависимости и показывает сценарий
        |
        v
services.py
  координирует покупку и защищает порядок изменений
        |
        +--> contracts.py: DiscountPolicy
        |
        +--> models.py: Car, Customer, Dealership, SaleReceipt
                         |
                         +--> enums.py: CarStatus

errors.py
  понятные бизнес-исключения
```

Направление зависимостей должно быть понятным. Модели не импортируют `main`. Сервис не вызывает `input()`. `main` является точкой сборки и может печатать демонстрационный результат.

### Где размещать правило

- правило одного объекта — метод или property этого объекта;
- координация нескольких объектов — service;
- выбор алгоритма скидки — policy;
- представление конечного состояния — Enum;
- перенос результата без изменения — frozen dataclass;
- ввод, печать и сборка — `main`.

## 29. Типичные ошибки недели

1. Общий изменяемый список как атрибут класса.
2. `self` забыли в объявлении или вызвали метод на классе без экземпляра.
3. `__init__` пытается вернуть объект.
4. Валидация есть только в CLI, а модель допускает некорректное состояние.
5. Property выполняет неожиданную тяжёлую работу или меняет состояние при чтении.
6. `@staticmethod` используется для метода, которому на самом деле нужно состояние объекта.
7. Наследование выбрано только ради повторного использования кода.
8. Полиморфизм заменён цепочкой проверок точного типа.
9. Изменяемый dataclass ошибочно считается полностью immutable.
10. Enum сравнивают с произвольной строкой внутри модели.
11. `__repr__` раскрывает секретные данные.
12. `__eq__` возвращает `False` вместо `NotImplemented` для неизвестного типа без осознанной причины.
13. Изменяемый объект с полями равенства насильно сделан hashable.
14. `super()` объясняется как прямой вызов конкретного родителя.
15. Наследник сужает допустимые входы и ломает базовый контракт.
16. `Any` скрывает проблему вместо уточнения типа.
17. Аннотация расходится с реальным `return`.
18. Сервис сам создаёт инфраструктурную зависимость и становится трудно проверяемым.
19. Один класс выполняет ввод, расчёты, хранение и вывод.
20. Состояние меняется до завершения всех проверок операции.

## 30. Контрольные прогнозы

Сначала запиши ответ в файле дня или `notes.md`, затем запусти пример.

### Прогноз 1. Разные ли списки

```python
class Inventory:
    cars = []


first = Inventory()
second = Inventory()
first.cars.append("VIN-1")
print(second.cars)
```

Объясни не только вывод, но и место хранения списка.

### Прогноз 2. Затенение

```python
class Car:
    wheels = 4


car = Car()
car.wheels = 6
print(car.wheels, Car.wheels)
```

### Прогноз 3. Метод

```python
class Car:
    def describe(self) -> str:
        return "car"


car = Car()
print(car.describe())
print(Car.describe(car))
```

### Прогноз 4. Property

```python
class Stock:
    def __init__(self) -> None:
        self._quantity = 0

    @property
    def quantity(self) -> int:
        return self._quantity


stock = Stock()
stock.quantity = 10
```

Какой тип ошибки ожидается и почему?

### Прогноз 5. Dataclass equality

```python
from dataclasses import dataclass


@dataclass
class Vin:
    value: str


print(Vin("A") == Vin("A"))
print(Vin("A") is Vin("A"))
```

### Прогноз 6. Enum

```python
from enum import Enum


class Status(Enum):
    AVAILABLE = "available"


print(Status.AVAILABLE == "available")
print(Status.AVAILABLE.value == "available")
```

### Прогноз 7. `NotImplemented`

```python
class Car:
    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Car):
            return NotImplemented
        return True


print(Car() == 10)
```

### Прогноз 8. MRO

```python
class Root:
    def name(self) -> str:
        return "Root"


class Left(Root):
    pass


class Right(Root):
    def name(self) -> str:
        return "Right"


class Child(Left, Right):
    pass


print(Child.mro())
print(Child().name())
```

### Прогноз 9. Аннотации

```python
def double(value: int) -> int:
    return value * 2


print(double("car"))
```

Раздели ответ на runtime-поведение и вывод статического анализатора.

### Прогноз 10. Частичное изменение

```text
Покупатель имеет 50 000, автомобиль стоит 40 000 и уже продан.
Сервис сначала списывает деньги, а затем проверяет статус автомобиля.
```

Какое состояние останется после ошибки? Как изменить порядок шагов?

## 31. Вопросы самопроверки

1. Чем класс отличается от экземпляра?
2. Что Python передаёт в `self`?
3. Почему `__init__` не должен возвращать объект?
4. Где хранится атрибут, записанный через `self.name`?
5. Почему изменяемый атрибут класса может быть опасен?
6. Что такое инвариант?
7. Чем `_name` отличается от `__name` и `__name__`?
8. Когда property полезнее публичного атрибута?
9. Чем classmethod отличается от staticmethod?
10. Как различить композицию и наследование?
11. Что означает полиморфизм?
12. Чем ABC отличается от Protocol?
13. Что генерирует dataclass?
14. Почему изменяемому полю нужен `default_factory`?
15. Когда полезен Enum?
16. Чем `repr` отличается от `str`?
17. Почему `NotImplemented` не равен `NotImplementedError`?
18. Как связаны `__eq__` и `__hash__`?
19. Что делает объект iterable?
20. Что показывает MRO?
21. Почему `super()` — не просто «вызвать родителя»?
22. Проверяет ли Python аннотации типов автоматически?
23. Как Protocol поддерживает duck typing?
24. Что означает dependency injection?

## 32. Что будет позже

- алгоритмическая сложность, память, GIL и `asyncio` — неделя 4;
- pytest и полноценные автоматические тесты — недели 15–16;
- Django models и ORM — недели 9–11;
- транзакции и конкурентные изменения — этап PostgreSQL/Django;
- метаклассы, дескрипторы, редкие магические методы и продвинутый typing — отложенный Python Deep Dive.

## 33. Официальные источники

- [Classes](https://docs.python.org/3/tutorial/classes.html);
- [Data Model](https://docs.python.org/3/reference/datamodel.html);
- [Built-in Functions](https://docs.python.org/3/library/functions.html);
- [dataclasses](https://docs.python.org/3/library/dataclasses.html);
- [enum](https://docs.python.org/3/library/enum.html);
- [abc](https://docs.python.org/3/library/abc.html);
- [typing](https://docs.python.org/3/library/typing.html);
- [collections.abc](https://docs.python.org/3/library/collections.abc.html).
