Set Warnings "-notation-overridden".

Require Import Category.Lib.
Require Export Category.Theory.Isomorphism.
Require Export Category.Theory.Functor.

Generalizable All Variables.
Set Primitive Projections.
Set Universe Polymorphism.
Unset Transparent Obligations.

(* The canonical map just exposed the functor object mapping to the Coq type
   system, so that it can find the related functor through instance lookup.
   However, since only one such functor can match a given pattern, this is why
   it is termed canonical. *)

Class CanonicalMap `{C : Category} (F : C -> C) : Type := {
  map {A B} (f : A ~> B) : F A ~> F B;

  is_functor : C ⟶ C;
  fobj_related {A} : F A ≅ is_functor A;
  fmap_related {A B} (f : A ~> B) :
    map f ≈ from fobj_related ∘ fmap[is_functor] f ∘ to fobj_related
}.

Coercion is_functor : CanonicalMap >-> Functor.

Program Instance Identity_CanonicalMap `{C : Category} :
  CanonicalMap (fun X => X) | 9 := {
  map := fun _ _ f => f;
  is_functor := Id
}.

Program Instance Functor_CanonicalMap `{C : Category} `{F : C ⟶ C} :
  CanonicalMap F := {
  map := fun _ _ f => fmap[F] f;
  is_functor := F
}.

Program Instance Functor_Eta_CanonicalMap `{C : Category} `{F : C ⟶ C} :
  CanonicalMap (fun X => F X) := {
  map := fun _ _ f => fmap[F] f;
  is_functor := F
}.

Program Instance Functor_Map_CanonicalMap `{C : Category}
        `{G : @CanonicalMap C P} `{F : C ⟶ C} :
  CanonicalMap (fun X => F (P X)) := {
  map := fun _ _ f => fmap[F] (map f);
  is_functor := F ○ G
}.
Next Obligation.
  destruct G; simpl.
  apply fobj_respects.
  apply fobj_related0.
Defined.
Next Obligation.
  destruct G; simpl.
  rewrite <- !fmap_comp.
  apply fmap_respects.
  apply fmap_related0.
Defined.

Class Naturality (A : Type) : Type := {
  natural (f : A) : Type
}.

Arguments natural {A _} _ /.

Program Instance Identity_Naturality `{C : Category} :
  Naturality (∀ A, A ~> A) := {
  natural := fun f => ∀ X Y (g : X ~> Y), g ∘ f X ≈ f Y ∘ g
}.

Program Instance Functor_Naturality
        `{C : Category} `{D : Category} (F G : C ⟶ D) :
  Naturality (∀ A, F A ~> G A) := {
  natural := fun f =>
    ∀ X Y (g : X ~{C}~> Y), fmap[G] g ∘ f X ≈ f Y ∘ fmap[F] g
}.

Require Import Category.Functor.Constant.

Program Instance ConstMap `{C : Category} {B : C} :
  CanonicalMap (λ _, B) | 9 := {
  map := fun _ _ _ => id;
  is_functor := Constant _ B
}.

(*
Program Instance PartialApply_Product_Left `{F : C × C ⟶ C} {X : C} : C ⟶ C := {
  fobj := fun Y => F (X, Y);
  fmap := fun _ _ f => fmap[F] (id[X], f)
}.
Next Obligation.
  proper.
  rewrite X1; reflexivity.
Qed.
Next Obligation.
  rewrite <- fmap_comp.
  simpl.
  rewrite id_left.
  reflexivity.
Qed.

Program Instance PartialApply_Curried_Left `{F : C ⟶ [C, C]} {X : C} : C ⟶ C := {
  fobj := fun Y => F X Y;
  fmap := fun _ _ f => fmap[F X] f
}.
Next Obligation. apply fmap_comp. Qed.

Program Instance PartialApply_Product_Right `{F : C × C ⟶ C} {Y : C} : C ⟶ C := {
  fobj := fun X => F (X, Y);
  fmap := fun _ _ f => fmap[F] (f, id[Y])
}.
Next Obligation.
  proper.
  rewrite X0; reflexivity.
Qed.
Next Obligation.
  rewrite <- fmap_comp.
  simpl.
  rewrite id_left.
  reflexivity.
Qed.

Program Instance PartialApply_Curried_Right `{F : C ⟶ [C, C]} {Y : C} : C ⟶ C := {
  fobj := fun X => F X Y;
  fmap := fun _ _ f => fmap[F] f Y
}.
Next Obligation.
  proper.
  sapply (@fmap_respects _ _ F X Y0 x y X0).
Qed.
Next Obligation.
  pose proof (@fmap_id _ _ F X Y).
  simpl in X0.
  rewrite X0.
  apply fmap_id.
Qed.
Next Obligation.
  sapply (@fmap_comp _ _ F X Y0 Z f g Y).
Qed.
*)

Program Instance ArityOne `{C : Category}
        (P : C -> C) `{F : @CanonicalMap C P}
        (Q : C -> C) `{G : @CanonicalMap C Q} :
  @Naturality (∀ A, P A ~> Q A) := {
  natural := fun f => ∀ X Y (g : X ~> Y), @map _ _ G _ _ g ∘ f X ≈ f Y ∘ @map _ _ F _ _ g
}.

Program Instance ArityTwo `{C : Category}
        (P : C -> C -> C)
            `{FA : ∀ B, @CanonicalMap C (fun A => P A B)}
            `{FB : ∀ A, @CanonicalMap C (fun B => P A B)}
        (Q : C -> C -> C)
            `{GA : ∀ B, @CanonicalMap C (fun A => Q A B)}
            `{GB : ∀ A, @CanonicalMap C (fun B => Q A B)} :
  @Naturality (∀ A B, P A B ~> Q A B) := {
  natural := fun f => ∀ X Y (g : X ~> Y) Z W (h : Z ~> W),
    @map _ _ (GB _) _ _ h ∘ @map _ _ (GA _) _ _ g ∘ f X Z
      ≈ f Y W ∘ @map _ _ (FB _) _ _ h ∘ @map _ _ (FA _) _ _ g
}.

Program Instance ArityThree `{C : Category}
        (P : C -> C -> C -> C)
            `{FA : ∀ B D : C, @CanonicalMap C (fun A => P A B D)}
            `{FB : ∀ A D : C, @CanonicalMap C (fun B => P A B D)}
            `{FC : ∀ A B : C, @CanonicalMap C (fun D => P A B D)}
        (Q : C -> C -> C -> C)
            `{GA : ∀ B D : C, @CanonicalMap C (fun A => Q A B D)}
            `{GB : ∀ A D : C, @CanonicalMap C (fun B => Q A B D)}
            `{GC : ∀ A B : C, @CanonicalMap C (fun D => Q A B D)} :
  @Naturality (∀ A B D, P A B D ~> Q A B D) := {
  natural := fun f => ∀ X Y (g : X ~> Y)
                        Z W (h : Z ~> W)
                        V U (i : V ~> U),
    @map _ _ (GC _ _) _ _ i ∘
    @map _ _ (GB _ _) _ _ h ∘
    @map _ _ (GA _ _) _ _ g
      ∘ f X Z V
      ≈ f Y W U
      ∘ @map _ _ (FC _ _) _ _ i
      ∘ @map _ _ (FB _ _) _ _ h
      ∘ @map _ _ (FA _ _) _ _ g
}.

Program Instance ArityFour `{C : Category}
        (P : C -> C -> C -> C -> C)
            `{FA : ∀ B D E : C, @CanonicalMap C (fun A => P A B D E)}
            `{FB : ∀ A D E : C, @CanonicalMap C (fun B => P A B D E)}
            `{FC : ∀ A B E : C, @CanonicalMap C (fun D => P A B D E)}
            `{FD : ∀ A B D : C, @CanonicalMap C (fun E => P A B D E)}
        (Q : C -> C -> C -> C -> C)
            `{GA : ∀ B D E : C, @CanonicalMap C (fun A => Q A B D E)}
            `{GB : ∀ A D E : C, @CanonicalMap C (fun B => Q A B D E)}
            `{GC : ∀ A B E : C, @CanonicalMap C (fun D => Q A B D E)}
            `{GD : ∀ A B D : C, @CanonicalMap C (fun E => Q A B D E)} :
  @Naturality (∀ A B D E, P A B D E ~> Q A B D E) := {
  natural := fun f => ∀ X Y (g : X ~> Y)
                        Z W (h : Z ~> W)
                        V U (i : V ~> U)
                        T S (j : T ~> S),
    @map _ _ (GD _ _ _) _ _ j ∘
    @map _ _ (GC _ _ _) _ _ i ∘
    @map _ _ (GB _ _ _) _ _ h ∘
    @map _ _ (GA _ _ _) _ _ g
      ∘ f X Z V T
      ≈ f Y W U S
      ∘ @map _ _ (FD _ _ _) _ _ j
      ∘ @map _ _ (FC _ _ _) _ _ i
      ∘ @map _ _ (FB _ _ _) _ _ h
      ∘ @map _ _ (FA _ _ _) _ _ g
}.


Program Instance ArityFive `{C : Category}
        (P : C -> C -> C -> C -> C -> C)
            `{FA : ∀ B D E F : C, @CanonicalMap C (fun A => P A B D E F)}
            `{FB : ∀ A D E F : C, @CanonicalMap C (fun B => P A B D E F)}
            `{FC : ∀ A B E F : C, @CanonicalMap C (fun D => P A B D E F)}
            `{FD : ∀ A B D F : C, @CanonicalMap C (fun E => P A B D E F)}
            `{FE : ∀ A B D E : C, @CanonicalMap C (fun F => P A B D E F)}
        (Q : C -> C -> C -> C -> C -> C)
            `{GA : ∀ B D E F : C, @CanonicalMap C (fun A => Q A B D E F)}
            `{GB : ∀ A D E F : C, @CanonicalMap C (fun B => Q A B D E F)}
            `{GC : ∀ A B E F : C, @CanonicalMap C (fun D => Q A B D E F)}
            `{GD : ∀ A B D F : C, @CanonicalMap C (fun E => Q A B D E F)}
            `{GE : ∀ A B D E : C, @CanonicalMap C (fun F => Q A B D E F)} :
  @Naturality (∀ A B D E F, P A B D E F ~> Q A B D E F) := {
  natural := fun f => ∀ X Y (g : X ~> Y)
                        Z W (h : Z ~> W)
                        V U (i : V ~> U)
                        T S (j : T ~> S)
                        Q R (k : Q ~> R),
    @map _ _ (GE _ _ _ _) _ _ k ∘
    @map _ _ (GD _ _ _ _) _ _ j ∘
    @map _ _ (GC _ _ _ _) _ _ i ∘
    @map _ _ (GB _ _ _ _) _ _ h ∘
    @map _ _ (GA _ _ _ _) _ _ g
      ∘ f X Z V T Q
      ≈ f Y W U S R
      ∘ @map _ _ (FE _ _ _ _) _ _ k
      ∘ @map _ _ (FD _ _ _ _) _ _ j
      ∘ @map _ _ (FC _ _ _ _) _ _ i
      ∘ @map _ _ (FB _ _ _ _) _ _ h
      ∘ @map _ _ (FA _ _ _ _) _ _ g
}.

Program Instance Transform_ArityOne `{C : Category}
        (P : C -> C) `{@CanonicalMap C P}
        (Q : C -> C) `{@CanonicalMap C Q} :
  @Naturality (∀ A, P A ≅ Q A) := {
  natural := fun f => natural (fun A => to (f A)) *
                      natural (fun A => from (f A))
}.

Program Instance Transform_ArityTwo `{C : Category}
        (P : C -> C -> C)
            `{∀ B, @CanonicalMap C (fun A => P A B)}
            `{∀ A, @CanonicalMap C (fun B => P A B)}
        (Q : C -> C -> C)
            `{∀ B, @CanonicalMap C (fun A => Q A B)}
            `{∀ A, @CanonicalMap C (fun B => Q A B)} :
  @Naturality (∀ A B, P A B ≅ Q A B) := {
  natural := fun f => natural (fun A B => to (f A B)) *
                      natural (fun A B => from (f A B))
}.

Program Instance Transform_ArityThree `{C : Category}
        (P : C -> C -> C -> C)
            `{∀ B D : C, @CanonicalMap C (fun A => P A B D)}
            `{∀ A D : C, @CanonicalMap C (fun B => P A B D)}
            `{∀ A B : C, @CanonicalMap C (fun D => P A B D)}
        (Q : C -> C -> C -> C)
            `{∀ B D : C, @CanonicalMap C (fun A => Q A B D)}
            `{∀ A D : C, @CanonicalMap C (fun B => Q A B D)}
            `{∀ A B : C, @CanonicalMap C (fun D => Q A B D)} :
  @Naturality (∀ A B D, P A B D ≅ Q A B D) := {
  natural := fun f => natural (fun A B D => to (f A B D)) *
                      natural (fun A B D => from (f A B D))
}.

Program Instance Transform_ArityFour `{C : Category}
        (P : C -> C -> C -> C -> C)
            `{∀ B D E : C, @CanonicalMap C (fun A => P A B D E)}
            `{∀ A D E : C, @CanonicalMap C (fun B => P A B D E)}
            `{∀ A B E : C, @CanonicalMap C (fun D => P A B D E)}
            `{∀ A B D : C, @CanonicalMap C (fun E => P A B D E)}
        (Q : C -> C -> C -> C -> C)
            `{∀ B D E : C, @CanonicalMap C (fun A => Q A B D E)}
            `{∀ A D E : C, @CanonicalMap C (fun B => Q A B D E)}
            `{∀ A B E : C, @CanonicalMap C (fun D => Q A B D E)}
            `{∀ A B D : C, @CanonicalMap C (fun E => Q A B D E)} :
  @Naturality (∀ A B D E, P A B D E ≅ Q A B D E) := {
  natural := fun f => natural (fun A B D E => to (f A B D E)) *
                      natural (fun A B D E => from (f A B D E))
}.


Program Instance Transform_ArityFive `{C : Category}
        (P : C -> C -> C -> C -> C -> C)
            `{∀ B D E F : C, @CanonicalMap C (fun A => P A B D E F)}
            `{∀ A D E F : C, @CanonicalMap C (fun B => P A B D E F)}
            `{∀ A B E F : C, @CanonicalMap C (fun D => P A B D E F)}
            `{∀ A B D F : C, @CanonicalMap C (fun E => P A B D E F)}
            `{∀ A B D E : C, @CanonicalMap C (fun F => P A B D E F)}
        (Q : C -> C -> C -> C -> C -> C)
            `{∀ B D E F : C, @CanonicalMap C (fun A => Q A B D E F)}
            `{∀ A D E F : C, @CanonicalMap C (fun B => Q A B D E F)}
            `{∀ A B E F : C, @CanonicalMap C (fun D => Q A B D E F)}
            `{∀ A B D F : C, @CanonicalMap C (fun E => Q A B D E F)}
            `{∀ A B D E : C, @CanonicalMap C (fun F => Q A B D E F)} :
  @Naturality (∀ A B D E F, P A B D E F ≅ Q A B D E F) := {
  natural := fun f => natural (fun A B D E F => to (f A B D E F)) *
                      natural (fun A B D E F => from (f A B D E F))
}.
